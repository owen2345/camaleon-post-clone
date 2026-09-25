# frozen_string_literal: true

# The plugin's admin settings page renders the two options its on_active hook registered, and saving
# it stores them as the plugin's custom field values.
RSpec.describe 'the camaleon_post_clone admin settings' do
  init_site

  let(:settings_path) { '/admin/plugins/camaleon_post_clone/settings' }
  let(:plugin) { @site.plugins.find_by!(slug: 'camaleon_post_clone') }

  before do
    store_current_site(@site)
    plugin_install('camaleon_post_clone')
    sign_in_as(cama_admin_user, site: @site)
  end

  it 'shows both options' do
    get settings_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('[plugin_clone_custom_fields]').and include('[plugin_clone_save_as_pending]')
  end

  it 'stores the submitted options and redirects back to the settings page' do
    post settings_path, params: { field_options: plugin_field_options(plugin, 'plugin_clone_save_as_pending', '1') }

    expect(response).to redirect_to(settings_path)
    expect(flash[:notice]).to eq(I18n.t('plugin.post_clone.message.settings_saved'))
    expect(plugin.reload.get_field_value('plugin_clone_save_as_pending')).to eq('1')
    expect(plugin.get_field_value('plugin_clone_custom_fields')).to be_nil
  end

  it 'refuses the page while the plugin is inactive' do
    plugin_uninstall('camaleon_post_clone')

    get settings_path

    expect(response).to have_http_status(:redirect)
  end
end
