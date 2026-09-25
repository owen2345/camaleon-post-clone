# frozen_string_literal: true

# The plugin reaches the admin through two hooks: edit_post appends a clone link to the post editor's
# sidebar, and plugin_options adds a Settings link under the plugin in the plugin manager.
RSpec.describe 'the links the plugin adds to the admin' do
  init_site

  before do
    store_current_site(@site)
    plugin_install('camaleon_post_clone')
    sign_in_as(cama_admin_user, site: @site)
  end

  it 'adds a clone link to the post editor' do
    get "/admin/post_type/#{@post.post_type_id}/posts/#{@post.id}/edit"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("href='/admin/plugins/camaleon_post_clone/clone/#{@post.id}'")
  end

  it 'shows no clone link to a user who cannot create posts of the type' do
    editor = user_with_manager_grants({ 'plugins' => 1 }, 'plugins-editor',
                                      post_type_meta: { edit_other: [@post.post_type_id.to_s] })
    sign_in_as(editor, site: @site)

    get "/admin/post_type/#{@post.post_type_id}/posts/#{@post.id}/edit"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('/admin/plugins/camaleon_post_clone/clone/')
  end

  it 'adds no clone link to the new post form' do
    get "/admin/post_type/#{@post.post_type_id}/posts/new"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('/admin/plugins/camaleon_post_clone/clone/')
  end

  it 'adds a Settings link under the plugin in the plugin manager' do
    get '/admin/plugins'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(<a href="/admin/plugins/camaleon_post_clone/settings">Settings</a>))
  end
end
