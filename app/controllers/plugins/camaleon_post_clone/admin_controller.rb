# frozen_string_literal: true

# The plugin's admin endpoints: the clone action the post editor links to, and the settings page
# holding the two options its on_active hook registers.
class Plugins::CamaleonPostClone::AdminController < CamaleonCms::Apps::PluginsAdminController
  include Plugins::CamaleonPostClone::MainHelper

  def clone # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    i = %i[term_relationships metas]
    i << :custom_field_values if @plugin.get_field_value('plugin_clone_custom_fields')
    post = current_site.posts.find(params[:id])
    # Cloning reads the source and creates a post of its type, so it needs the rights the editor needs
    # for edit and new; the plugin permission the base controller checks is not enough on its own.
    authorize! :update, post
    authorize! :create_post, post.post_type
    clone = post.deep_clone(include: i)
    clone.post_type = post.post_type
    slugs = clone.slug.translations
    titles = clone.title.translations
    slugs.each do |k, v|
      slugs[k] = current_site.get_valid_post_slug(v)
      titles[k] = "#{titles[k]} (clone)"
    end
    if slugs.empty?
      clone.slug = current_site.get_valid_post_slug(clone.slug)
      clone.title << ' (clone)'
    else
      clone.slug = slugs.to_translate
      clone.title = titles.to_translate
    end
    # The clone is the cloner's own post, as a post the editor creates is (`update` on it then depends
    # on the cloner's `edit` right, not on the source author's identity).
    clone.user_id = cama_current_user.id
    clone.status = 'pending' if @plugin.get_field_value('plugin_clone_save_as_pending')
    clone.save!
    flash[:notice] = t('plugin.post_clone.message.content_cloned').to_s
    redirect_to clone.decorate.the_edit_url
  end

  def settings; end

  def settings_save
    @plugin.set_field_values(params[:field_options])
    flash[:notice] = t('plugin.post_clone.message.settings_saved').to_s
    redirect_to action: :settings
  end
end
