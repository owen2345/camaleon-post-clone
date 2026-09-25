# frozen_string_literal: true

# The plugin's admin endpoints: the clone action the post editor links to, and the settings page
# holding the two options its on_active hook registers.
class Plugins::CamaleonPostClone::AdminController < CamaleonCms::Apps::PluginsAdminController
  include Plugins::CamaleonPostClone::MainHelper

  # The statuses the post editor offers: core's own list where it carries one (camaleon_cms after
  # 2.9.4), else the same literal. A source outside them is a trashed post or an autosave buffer
  # (`draft_child`, a draft the editor keeps under its parent, saved into the parent on update):
  # neither is a status a new post may be born with.
  EDITOR_STATUSES = if CamaleonCms::Post.const_defined?(:EDITOR_STATUSES)
                      CamaleonCms::Post::EDITOR_STATUSES
                    else
                      %w[published pending draft].freeze
                    end

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
    # unfiltered-content right, as for a post they create, and the copied summary is scanned here as
    # the post editor scans a submitted one; a refusal is answered as a refused save is, not raised
    # out of this GET as a 500.
    refusal = summary_refusal(post) || save_refusal(clone)
    if refusal
      flash[:error] = refusal
      redirect_to post.decorate.the_edit_url
    else
      flash[:notice] = t('plugin.post_clone.message.content_cloned').to_s
      redirect_to clone.decorate.the_edit_url
    end
  end

  def settings; end

  def settings_save
    @plugin.set_field_values(params[:field_options])
    flash[:notice] = t('plugin.post_clone.message.settings_saved').to_s
    redirect_to action: :settings
  end

  private

  # `meta[summary]` is content the default theme renders verbatim, and a meta row passes no model
  # validation, so core's post editor scans a submitted summary in the controller for a user without
  # the unfiltered-content right. The clone copies the source's summary meta as stored, so it is held
  # to the same detector, allowlist and messages here; a right holder's clone copies it verbatim.
  def summary_refusal(source)
    summary = source.get_meta('summary')
    return if summary.blank? || can?(:post_content_unfiltered_html, source.post_type)

    if CamaleonCms::UnsafeMarkup.too_large?(summary)
      "meta[summary] #{cama_t('camaleon_cms.admin.post.message.content_too_large')}"
    elsif CamaleonCms::UnsafeMarkup.unsafe_html?(summary, tags: CamaleonCms::Post::CONTENT_ALLOWED_TAGS,
                                                          attributes: CamaleonCms::Post::CONTENT_ALLOWED_ATTRIBUTES)
      "meta[summary] #{cama_t('camaleon_cms.admin.post.message.content_rejected')}"
    end
  end

  # Why the clone's save was refused, or nil once it is saved. A copied custom field value core's
  # gate refuses fails the save through the association's generic "is invalid"; the value's own
  # message, naming the field and the reason as the post editor's refusal does, replaces it.
  def save_refusal(clone)
    return if clone.save

    value_messages = clone.custom_field_values.flat_map { |value| value.errors.full_messages }
    clone.errors.delete(:custom_field_values) if value_messages.any?
    (clone.errors.full_messages + value_messages).to_sentence
  end

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
