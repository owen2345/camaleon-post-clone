# frozen_string_literal: true

# The clone endpoint copies a post of the current site -- its content, type, categories, tags and
# metas, plus its custom field values when that option is on -- under a "(clone)" title and a fresh
# slug, keeps or downgrades its status per the pending option, and opens the copy in the editor.
RSpec.describe 'cloning a post' do
  init_site

  let(:plugin) { @site.plugins.find_by!(slug: 'camaleon_post_clone') }
  let(:clone_path) { "/admin/plugins/camaleon_post_clone/clone/#{@post.id}" }

  before do
    store_current_site(@site)
    plugin_install('camaleon_post_clone')
    sign_in_as(cama_admin_user, site: @site)
    @existing_ids = @site.posts.pluck(:id)
  end

  def cloned_post
    new_posts = @site.posts.where.not(id: @existing_ids).to_a
    expect(new_posts.size).to eq(1)
    new_posts.first
  end

  it 'creates a copy with a suffixed title, a fresh slug and the same content, and opens its editor' do
    get clone_path

    copy = cloned_post
    expect(copy.title).to eq("#{@post.title} (clone)")
    expect(copy.slug).not_to eq(@post.slug)
    expect(copy.post_type_id).to eq(@post.post_type_id)
    expect(copy.content).to eq(@post.content)
    expect(copy.status).to eq(@post.status)
    expect(response).to redirect_to(%r{/admin/post_type/#{copy.post_type_id}/posts/#{copy.id}/edit\z})
    expect(flash[:notice]).to eq(I18n.t('plugin.post_clone.message.content_cloned'))
  end

  it 'copies the categories, tags and metas' do
    category = @post.post_type.categories.create!(name: 'News', slug: 'news')
    @post.term_relationships.create!(term_taxonomy_id: category.id)
    @post.set_meta('color', 'red')

    get clone_path

    copy = cloned_post
    expect(copy.term_relationships.pluck(:term_taxonomy_id))
      .to match_array(@post.term_relationships.pluck(:term_taxonomy_id))
    expect(copy.get_meta('color')).to eq('red')
  end

  it 'suffixes every translation of a translated title and slug' do
    @post.update!(title: '<!--:en-->Sample<!--:--><!--:es-->Muestra<!--:-->',
                  slug: '<!--:en-->sample<!--:--><!--:es-->muestra<!--:-->')

    get clone_path

    copy = cloned_post
    expect(copy.title.translations).to eq(en: 'Sample (clone)', es: 'Muestra (clone)')
    expect(copy.slug.translations.keys).to eq(%i[en es])
    expect(copy.slug.translations.values).to all(match(/\A(sample|muestra)-\d+\z/))
  end

  it 'saves the copy as pending when that option is on' do
    enable_plugin_setting(plugin, 'plugin_clone_save_as_pending')

    get clone_path

    expect(cloned_post.status).to eq('pending')
  end

  it 'copies the custom field values when that option is on' do
    group = @post.post_type.add_custom_field_group({ name: 'Extra', slug: 'extra' })
    group.add_manual_field({ name: 'Subtitle', slug: 'subtitle' }, { field_key: 'text_box' })
    field = group.fields.first
    values = { group.id.to_s => { 'subtitle' => { 'id' => field.id.to_s, 'values' => { '0' => 'Sub' } } } }
    @post.set_field_values(values.with_indifferent_access)
    enable_plugin_setting(plugin, 'plugin_clone_custom_fields')

    get clone_path

    expect(cloned_post.get_field_value('subtitle')).to eq('Sub')
  end

  it 'refuses a post of another site' do
    other_post = create(:site).decorate.the_post('sample-post')

    get "/admin/plugins/camaleon_post_clone/clone/#{other_post.id}"

    expect(response).to have_http_status(:redirect)
    expect(CamaleonCms::Post.where("title LIKE '% (clone)'")).to be_empty
  end

  it 'refuses a user who cannot manage plugins' do
    sign_in_as(user_with_manager_grants({}, 'clerk'), site: @site)

    get clone_path

    expect(response).not_to have_http_status(:ok)
    expect(@site.posts.where.not(id: @existing_ids)).to be_empty
  end

  it 'is refused while the plugin is inactive' do
    plugin_uninstall('camaleon_post_clone')

    get clone_path

    expect(response).to have_http_status(:redirect)
    expect(@site.posts.where.not(id: @existing_ids)).to be_empty
  end
end
