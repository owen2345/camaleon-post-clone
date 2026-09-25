# frozen_string_literal: true

# The clone endpoint was authorized by the plugin admin base check alone (`manage plugins`), so a
# plugins manager with no post rights cloned any post of the site, other authors' drafts included,
# and read its content back in the copy. Cloning now needs what the editor needs for the same post:
# the right to edit the source and the right to create posts of its type.
RSpec.describe 'cloning a post is authorized on the source post' do
  init_site

  let(:post_type) { @post.post_type }
  let(:clone_path) { "/admin/plugins/camaleon_post_clone/clone/#{@post.id}" }

  before do
    store_current_site(@site)
    plugin_install('camaleon_post_clone')
    @post.update!(status: 'draft')
    @existing_ids = @site.posts.pluck(:id)
  end

  def new_posts
    @site.posts.where.not(id: @existing_ids)
  end

  it 'refuses a plugins manager who cannot edit posts of the type' do
    sign_in_as(user_with_manager_grants({ 'plugins' => 1 }, 'plugins-manager'), site: @site)

    get clone_path

    expect(response).to have_http_status(:redirect)
    expect(flash[:error]).to be_present
    expect(new_posts).to be_empty
  end

  it 'refuses a plugins manager who can edit the post but not create posts of its type' do
    editor = user_with_manager_grants({ 'plugins' => 1 }, 'plugins-editor',
                                      post_type_meta: { edit_other: [post_type.id.to_s] })
    sign_in_as(editor, site: @site)

    get clone_path

    expect(response).to have_http_status(:redirect)
    expect(flash[:error]).to be_present
    expect(new_posts).to be_empty
  end

  it 'clones for a plugins manager who can edit the post and create posts of its type' do
    author = user_with_manager_grants({ 'plugins' => 1 }, 'plugins-author',
                                      post_type_meta: { edit: [post_type.id.to_s], edit_other: [post_type.id.to_s] })
    sign_in_as(author, site: @site)

    get clone_path

    expect(new_posts.count).to eq(1)
    expect(response).to redirect_to(%r{/admin/post_type/#{post_type.id}/posts/#{new_posts.first.id}/edit\z})
  end

  it 'makes the clone the cloner\'s own post, as creating one does' do
    author = user_with_manager_grants({ 'plugins' => 1 }, 'plugins-author',
                                      post_type_meta: { edit: [post_type.id.to_s], edit_other: [post_type.id.to_s] })
    sign_in_as(author, site: @site)

    get clone_path

    expect(new_posts.first.user_id).to eq(author.id)
  end

  it 'clones a published post as pending for a user who cannot publish posts of its type' do
    @post.update!(status: 'published')
    editor = user_with_manager_grants({ 'plugins' => 1 }, 'plugins-editor',
                                      post_type_meta: { edit: [post_type.id.to_s], edit_publish: [post_type.id.to_s] })
    sign_in_as(editor, site: @site)

    get clone_path

    expect(new_posts.count).to eq(1)
    expect(new_posts.first.status).to eq('pending')
    expect(response).to redirect_to(%r{/admin/post_type/#{post_type.id}/posts/#{new_posts.first.id}/edit\z})
  end

  it 'keeps a published clone published for a user who can publish posts of its type' do
    @post.update!(status: 'published')
    publisher = user_with_manager_grants({ 'plugins' => 1 }, 'plugins-publisher',
                                         post_type_meta: { edit: [post_type.id.to_s], edit_other: [post_type.id.to_s],
                                                           publish: [post_type.id.to_s] })
    sign_in_as(publisher, site: @site)

    get clone_path

    expect(new_posts.first.status).to eq('published')
  end
end
