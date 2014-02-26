require 'redmine'
require 'restrict'

# Patches to the Redmine core.
require 'dispatcher'

Dispatcher.to_prepare do
  ApplicationController.send(:include, AppControllerPatch)

  unless Mailer.included_modules.include? MailerPatch
    Mailer.send(:include, MailerPatch)
  end
end

Redmine::Plugin.register :redmine_subscription do
  name 'PMP HQ Subscription'
  author 'PMP HQ'
  description 'Provide subscription billing'
  version '1.0'
  menu :account_menu, :subs, {:controller => "subs", :action => 'index'}, :caption => 'Subscription', :if => Proc.new {User.current.admin?}

  as = YAML::load(File.open("#{RAILS_ROOT}/config/asettings.yml"))
  $uid = as["uid"]
  $pphost = as["pphost"]
  $dbcon = as["dbcon"]
  $api_login = as["api_login"]
  $api_key = as["api_key"]
  $gateway = as["gateway"]
end