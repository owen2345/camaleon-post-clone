Rails.application.routes.draw do

    scope PluginRoutes.system_info["relative_url_root"] do
      #Admin Panel
      scope 'admin', as: 'admin' do
        namespace 'plugins' do
          namespace 'camaleon_post_clone' do
            get 'settings' => "admin#settings"
            post 'settings' => "admin#settings_save"
            get 'clone/:id' => "admin#clone", as: "clone"
          end
        end
      end
    end
  end
