val_zone = attribute('DefaultFirewalldProfile', description: 'Choose the default profile for Firewalld.')

control 'Firewalld Enabled' do
  impact 1.0
  title 'Firewalld is Enabled'
  desc 'Validates that the Firewalld package is installed, running, and that the default zone is public'

  describe firewalld do
    it { should be_running }
    its('default_zone') { should eq val_zone }
  end  
end
