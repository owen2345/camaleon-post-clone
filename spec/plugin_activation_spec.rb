# frozen_string_literal: true

# camaleon_post_clone is not one of Camaleon's default plugins, so a site never gets it on install --
# activation is an explicit step (admin plugin manager, or plugin_install here). Installing runs the
# plugin's on_active hook, which creates its settings group; uninstalling runs on_inactive, which
# removes it.
RSpec.describe 'camaleon_post_clone plugin activation', type: :model do
  init_site

  before { store_current_site(@site) }

  it 'is not auto-installed with a new site' do
    expect(@site.plugins.pluck(:slug)).not_to include('camaleon_post_clone')
  end

  it 'installs for a site with its two settings in one group' do
    plugin_model = plugin_install('camaleon_post_clone')

    expect(plugin_model).to be_active
    expect(@site.plugins.active.pluck(:slug)).to include('camaleon_post_clone')
    group = plugin_model.get_field_groups.find_by!(slug: 'plugin_clone_custom_settings')
    expect(group.fields.pluck(:slug)).to contain_exactly('plugin_clone_custom_fields', 'plugin_clone_save_as_pending')
  end

  it 'deactivates again, removing the settings group' do
    plugin_install('camaleon_post_clone')
    plugin_model = plugin_uninstall('camaleon_post_clone')

    expect(plugin_model).not_to be_active
    expect(plugin_model.get_field_groups).to be_empty
  end
end
