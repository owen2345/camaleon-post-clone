# frozen_string_literal: true

# The clone is saved as the cloner's own post, so core's content scan runs on it for a cloner
# without the unfiltered-content right, as it does on a post they create. A refused clone was raised
# out of the GET clone route as a 500; it is answered like a refused save: a flash naming the problem
# on the source's editor, and no post written.
RSpec.describe 'cloning a post whose content the scan refuses for the cloner' do
  init_site

  let(:post_type) { @post.post_type }
  let(:clone_path) { "/admin/plugins/camaleon_post_clone/clone/#{@post.id}" }

  before do
    store_current_site(@site)
    plugin_install('camaleon_post_clone')
    @post.unfiltered_content!.update!(content: '<p>Hello</p><script>alert(1)</script>')
    @existing_ids = @site.posts.pluck(:id)
  end

  def new_posts
    @site.posts.where.not(id: @existing_ids)
  end

  it 'refuses the clone with a flash error on the source editor for a cloner without the unfiltered right' do
    author = user_with_manager_grants({ 'plugins' => 1 }, 'plugins-author',
                                      post_type_meta: { edit: [post_type.id.to_s], edit_other: [post_type.id.to_s] })
    sign_in_as(author, site: @site)

    get clone_path

    expect(response).to redirect_to(%r{/admin/post_type/#{post_type.id}/posts/#{@post.id}/edit\z})
    expect(flash[:error]).to include(I18n.t('camaleon_cms.admin.post.message.content_rejected'))
    expect(new_posts).to be_empty
  end

  it 'clones the content verbatim for a cloner with the unfiltered right' do
    trusted = user_with_manager_grants({ 'plugins' => 1 }, 'plugins-trusted',
                                       post_type_meta: { edit: [post_type.id.to_s], edit_other: [post_type.id.to_s],
                                                         post_content_unfiltered_html: [post_type.id.to_s] })
    sign_in_as(trusted, site: @site)

    get clone_path

    expect(new_posts.count).to eq(1)
    expect(new_posts.first.content).to eq(@post.content)
  end
end
