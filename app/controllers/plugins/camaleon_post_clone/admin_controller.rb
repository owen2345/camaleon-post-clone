# frozen_string_literal: true

# The plugin's admin endpoints: the clone action the post editor links to, and the settings page
# holding the two options its on_active hook registers.
class Plugins::CamaleonPostClone::AdminController < CamaleonCms::Apps::PluginsAdminController
  include Plugins::CamaleonPostClone::MainHelper
  # Confines a submitted field_options to the slugs the plugin registered (see settings_save).
  include CamaleonCms::Admin::CustomFieldsConcern

  def clone # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    i = %i[term_relationships metas]
    i << :custom_field_values if @plugin.get_field_value('plugin_clone_custom_fields')
    post = current_site.posts.find(params[:id])
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
    clone.status = 'pending' if @plugin.get_field_value('plugin_clone_save_as_pending')
    clone.save!
    flash[:notice] = t('plugin.post_clone.message.content_cloned').to_s
    redirect_to clone.decorate.the_edit_url
  end

  def settings; end

  def settings_save
    # Only the plugin's registered settings are stored, as camaleon_cms's own admin controllers do.
    if params[:field_options].present?
      index_array_values
      @plugin.set_field_values(cama_permitted_field_options('Plugin'))
    end
    flash[:notice] = t('plugin.post_clone.message.settings_saved').to_s
    redirect_to action: :settings
  end

  private

  # The settings form's checkboxes submit values[] (camaleon_cms renames every other field's values[]
  # to values[<index>] in the browser but skips checkboxes), and cama_permitted_field_options permits
  # values only as an indexed hash, dropping the array. Both plugin settings are checkboxes, so the
  # array is re-keyed by index before the allow-list sees it; the stored values are the same either way.
  def index_array_values
    groups = params[:field_options]
    return unless groups.is_a?(ActionController::Parameters)

    groups.each_pair do |_group, fields|
      fields.each_pair { |_slug, field| index_field_values(field) } if fields.is_a?(ActionController::Parameters)
    end
  end

  def index_field_values(field)
    return unless field.is_a?(ActionController::Parameters) && field[:values].is_a?(Array)

    field[:values] = field[:values].each_with_index.to_h { |value, index| [index.to_s, value] }
  end
end
