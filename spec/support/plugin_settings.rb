# frozen_string_literal: true

# One of the plugin's checkbox settings the way the admin settings form submits it
# (field_options[<group id>][<field slug>][values][<index>]), so the specs exercise the same save path.
# Indifferent access because set_field_values reads the nested keys as Symbols, as it does from
# request parameters.
def plugin_field_options(plugin, slug, value)
  group = plugin.get_field_groups.find_by!(slug: 'plugin_clone_custom_settings')
  field = group.fields.find_by!(slug: slug)
  { group.id.to_s => { slug => { 'id' => field.id.to_s, 'values' => { '0' => value } } } }.with_indifferent_access
end

def enable_plugin_setting(plugin, slug)
  plugin.set_field_values(plugin_field_options(plugin, slug, '1'))
end
