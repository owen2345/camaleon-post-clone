# frozen_string_literal: true

# The plugin's admin endpoints: the clone action the post editor links to, and the settings page
# holding the two options its on_active hook registers.
class Plugins::CamaleonPostClone::AdminController < CamaleonCms::Apps::PluginsAdminController
  include Plugins::CamaleonPostClone::MainHelper

  # The statuses the post editor offers. A source outside them is a trashed post or an autosave
  # buffer (`draft_child`, a draft the editor keeps under its parent, saved into the parent on update):
  # neither is a status a new post may be born with.
  EDITOR_STATUSES = %w[published pending draft].freeze

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
    hold_status(clone, post)
    # The clone is saved as the cloner's post, so core scans its content for a cloner without the
    # unfiltered-content right, as for a post they create; a refusal is answered as a refused save is,
    # not raised out of this GET as a 500.
    if clone.save
      flash[:notice] = t('plugin.post_clone.message.content_cloned').to_s
      redirect_to clone.decorate.the_edit_url
    else
      flash[:error] = clone.errors.full_messages.to_sentence
      redirect_to post.decorate.the_edit_url
    end
  end

  def settings; end

  def settings_save
    @plugin.set_field_values(params[:field_options])
    flash[:notice] = t('plugin.post_clone.message.settings_saved').to_s
    redirect_to action: :settings
  end

  private

  # The clone's status: the source's when the editor offers it, else pending (a trashed source), and a
  # buffer's clone is a draft of its own, cut from the buffer's parent. Then pending when the plugin
  # option says so, and pending instead of a copied `published` for a user without the publish right,
  # as core downgrades it on create, update and restore, so cloning cannot publish for a user who
  # cannot. The clone never carries the source's publish date: the post stamps `published_at` when it
  # is saved published with the column blank, so a clone published now is dated now, and one
  # published later is dated then, as a created post is.
  def hold_status(clone, source)
    if source.draft_child?
      clone.status = 'draft'
      clone.post_parent = nil
    end
    clone.status = 'pending' unless EDITOR_STATUSES.include?(clone.status)
    clone.status = 'pending' if @plugin.get_field_value('plugin_clone_save_as_pending')
    clone.status = 'pending' if clone.published? && cannot?(:publish_post, clone.post_type)
    clone.published_at = nil
  end
end
