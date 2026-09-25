# frozen_string_literal: true

# End-to-end smoke test: boots a camaleon_cms-backed dummy app with this plugin loaded (the test env
# eager-loads, so a plugin class referencing a missing constant fails the whole boot) and asserts the
# camaleon_post_clone plugin is wired up -- discovered by the CMS as a gem-mode plugin, every hook its
# camaleon_plugin.json names defined on the plugin helper, and its admin routes drawn.
RSpec.describe 'camaleon_post_clone plugin', type: :model do
  it 'loads the engine and top-level constant' do
    expect(defined?(CamaleonPostClone)).to eq('constant')
    expect(CamaleonPostClone::VERSION).to be_a(String)
    expect(CamaleonPostClone::Engine.ancestors).to include(Rails::Engine)
  end

  it 'is discovered by Camaleon as a gem-mode plugin' do
    info = PluginRoutes.plugin_info('camaleon_post_clone')
    expect(info).to be_present
    expect(info['key']).to eq('camaleon_post_clone')
    expect(info['gem_mode']).to be(true)
  end

  it 'defines every hook method camaleon_plugin.json names on the plugin helper' do
    hook_methods = PluginRoutes.plugin_info('camaleon_post_clone')['hooks'].values.flatten.uniq.map(&:to_sym)

    expect(hook_methods).not_to be_empty
    expect(Plugins::CamaleonPostClone::MainHelper.instance_methods).to include(*hook_methods)
  end

  it 'draws its admin routes on the host application' do
    helpers = Rails.application.routes.url_helpers

    expect(helpers).to respond_to(:admin_plugins_camaleon_post_clone_settings_path)
    expect(helpers).to respond_to(:admin_plugins_camaleon_post_clone_clone_path)
  end
end
