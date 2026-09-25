# frozen_string_literal: true

# The settings save handed the submitted field_options to set_field_values unfiltered, so a request
# could store a value under any slug, registered or not, and a scalar field_options raised. The
# values are now confined to the slugs the plugin registered, as camaleon_cms's own admin
# controllers confine theirs.
RSpec.describe 'saving the plugin settings stores only its registered fields' do
  init_site

  let(:settings_path) { '/admin/plugins/camaleon_post_clone/settings' }
  let(:plugin) { @site.plugins.find_by!(slug: 'camaleon_post_clone') }
  let(:group) { plugin.get_field_groups.find_by!(slug: 'plugin_clone_custom_settings') }
  let(:field) { group.fields.find_by!(slug: 'plugin_clone_save_as_pending') }

  before do
    store_current_site(@site)
    plugin_install('camaleon_post_clone')
    sign_in_as(cama_admin_user, site: @site)
  end

  it 'drops a slug the plugin never registered and keeps a registered one' do
    post settings_path, params: { field_options: { group.id.to_s => {
      'plugin_clone_save_as_pending' => { 'id' => field.id.to_s, 'values' => { '0' => '1' } },
      'plugin_clone_forged' => { 'id' => field.id.to_s, 'values' => { '0' => '1' } }
    } } }

    expect(response).to redirect_to(settings_path)
    expect(plugin.custom_field_values.pluck(:custom_field_slug)).to contain_exactly('plugin_clone_save_as_pending')
  end

  it 'answers a scalar field_options without storing anything' do
    post settings_path, params: { field_options: 'forged' }

    expect(response).to redirect_to(settings_path)
    expect(plugin.custom_field_values).to be_empty
  end
end
