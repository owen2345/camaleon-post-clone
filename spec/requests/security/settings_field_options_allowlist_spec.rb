# frozen_string_literal: true

# The settings save handed the submitted field_options to set_field_values unfiltered, so a request
# could store a value under any slug, registered or not, and a scalar field_options raised. The
# values are now confined to the slugs registered for plugins, as camaleon_cms's own admin
# controllers confine theirs.
RSpec.describe 'saving the plugin settings stores only fields registered for plugins' do
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

  it 'drops a slug no plugin registered and keeps a registered one' do
    post settings_path, params: { field_options: { group.id.to_s => {
      'plugin_clone_save_as_pending' => { 'id' => field.id.to_s, 'values' => { '0' => '1' } },
      'plugin_clone_forged' => { 'id' => field.id.to_s, 'values' => { '0' => '1' } }
    } } }

    expect(response).to redirect_to(settings_path)
    expect(plugin.custom_field_values.pluck(:custom_field_slug)).to contain_exactly('plugin_clone_save_as_pending')
  end

  it 'stores a checkbox the form submits as values[], the shape the allow-list alone drops' do
    post settings_path, params: { field_options: { group.id.to_s => {
      'plugin_clone_save_as_pending' => { 'id' => field.id.to_s, 'values' => ['1'] }
    } } }

    expect(response).to redirect_to(settings_path)
    expect(plugin.custom_field_values.pluck(:custom_field_slug, :value)).to eq([%w[plugin_clone_save_as_pending 1]])
  end

  it 'answers a scalar field_options without storing anything' do
    post settings_path, params: { field_options: 'forged' }

    expect(response).to redirect_to(settings_path)
    expect(plugin.custom_field_values).to be_empty
  end

  context 'with a list where a group or a field belongs' do
    let(:entry) { { 'id' => field.id.to_s, 'values' => { '0' => '0' } } }

    before { enable_plugin_setting(plugin, 'plugin_clone_save_as_pending') }

    it 'answers a group sent as a list and keeps the stored settings' do
      post settings_path, params: { field_options: { '0' => [{ 'plugin_clone_save_as_pending' => entry }] } }

      expect(response).to redirect_to(settings_path)
      expect(plugin.custom_field_values.pluck(:custom_field_slug, :value)).to eq([%w[plugin_clone_save_as_pending 1]])
    end

    it 'answers a field sent as a list and keeps the stored settings' do
      post settings_path, params: { field_options: { '0' => { 'plugin_clone_save_as_pending' => [entry] } } }

      expect(response).to redirect_to(settings_path)
      expect(plugin.custom_field_values.pluck(:custom_field_slug, :value)).to eq([%w[plugin_clone_save_as_pending 1]])
    end
  end
end
