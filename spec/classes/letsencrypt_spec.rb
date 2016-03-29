require 'spec_helper'

describe 'letsencrypt' do
  {'Debian' => '9.0', 'RedHat' => '7.2'}.each do |osfamily, osversion|
    context "on #{osfamily} based operating systems" do
      let(:facts) { { osfamily: osfamily, operatingsystem: osfamily, operatingsystemrelease: osversion, path: '/usr/bin' } }

      context 'when specifying an email address with the email parameter' do
        let(:params) { additional_params.merge(default_params) }
        let(:default_params) { { email: 'foo@example.com' } }
        let(:additional_params) { { } }

        describe 'with defaults' do
          it { is_expected.to compile }

          it 'should contain the correct resources' do
            is_expected.to contain_class('letsencrypt::install').with({
              configure_epel: true,
              manage_install: true,
              manage_dependencies: true,
              repo: 'git://github.com/letsencrypt/letsencrypt.git',
              version: 'v0.4.0'
            }).that_notifies('Exec[initialize letsencrypt]')

            is_expected.to contain_ini_setting('/etc/letsencrypt/cli.ini email foo@example.com')
            is_expected.to contain_ini_setting('/etc/letsencrypt/cli.ini server https://acme-v01.api.letsencrypt.org/directory')
	    is_expected.to contain_ini_setting('/etc/letsencrypt/cli.ini rsa-key-size 4096')
            is_expected.to contain_exec('initialize letsencrypt')
            is_expected.to contain_class('letsencrypt::config').that_comes_before('Exec[initialize letsencrypt]')
          end
        end

        describe 'with custom path' do
          let(:additional_params) { { path: '/usr/lib/letsencrypt', install_method: 'vcs' } }
          it { is_expected.to contain_class('letsencrypt::install').with_path('/usr/lib/letsencrypt') }
          it { is_expected.to contain_exec('initialize letsencrypt').with_command('/usr/lib/letsencrypt/letsencrypt-auto -h') }
        end

        describe 'with custom repo' do
          let(:additional_params) { { repo: 'git://foo.com/letsencrypt.git' } }
          it { is_expected.to contain_class('letsencrypt::install').with_repo('git://foo.com/letsencrypt.git') }
        end

        describe 'with custom version' do
          let(:additional_params) { { version: 'foo' } }
          it { is_expected.to contain_class('letsencrypt::install').with_path('/opt/letsencrypt').with_version('foo') }
        end

        describe 'with custom package_ensure' do
          let(:additional_params) { { package_ensure: '0.3.0-1.el7' } }
          it { is_expected.to contain_class('letsencrypt::install').with_package_ensure('0.3.0-1.el7') }
        end

        describe 'with custom config file' do
          let(:additional_params) { { config_file: '/etc/letsencrypt/custom_config.ini' } }
          it { is_expected.to contain_ini_setting('/etc/letsencrypt/custom_config.ini server https://acme-v01.api.letsencrypt.org/directory') }
        end

        describe 'with custom config' do
          let(:additional_params) { { config: { 'foo' => 'bar' } } }
          it { is_expected.to contain_ini_setting('/etc/letsencrypt/cli.ini foo bar') }
        end

        describe 'with manage_config set to false' do
          let(:additional_params) { { manage_config: false } }
          it { is_expected.not_to contain_class('letsencrypt::config') }
        end

        describe 'with manage_install set to false' do
          let(:additional_params) { { manage_install: false } }
          it { is_expected.not_to contain_class('letsencrypt::install') }
        end

        describe 'with install_method => package' do
          let(:additional_params) { { install_method: 'package' } }
          it { is_expected.to contain_class('letsencrypt::install').with_install_method('package') }
          it { is_expected.to contain_exec('initialize letsencrypt').with_command('letsencrypt -h') }
        end

        describe 'with install_method => vcs' do
          let(:additional_params) { { install_method: 'vcs' } }
          it { is_expected.to contain_class('letsencrypt::install').with_install_method('vcs') }
          it { is_expected.to contain_exec('initialize letsencrypt').with_command('/opt/letsencrypt/letsencrypt-auto -h') }
        end

        context 'when not agreeing to the TOS' do
          let(:params) { { agree_tos: false } }
          it { is_expected.to raise_error Puppet::Error, /You must agree to the Let's Encrypt Terms of Service/ }
        end
      end

      context 'when specifying an email in $config' do
        let(:params) { { config: { 'email' => 'foo@example.com' } } }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_ini_setting('/etc/letsencrypt/cli.ini email foo@example.com') }
      end

      context 'when not specifying the email parameter or an email key in $config' do
        context 'with unsafe_registration set to false' do
          it { is_expected.to raise_error Puppet::Error, /Please specify an email address/ }
        end

        context 'with unsafe_registration set to true' do
          let(:params) {{ unsafe_registration: true }}
          it { is_expected.not_to contain_ini_setting('/etc/letsencrypt/cli.ini email foo@example.com') }
          it { is_expected.to contain_ini_setting('/etc/letsencrypt/cli.ini register-unsafely-without-email true') }
        end
      end
    end
  end

  context 'on unknown operating systems' do
    let(:facts) { { osfamily: 'Darwin', path: '/usr/bin' } }
    let(:params) { { email: 'foo@example.com' } }

    describe 'with defaults' do
      it { is_expected.to compile }

      it 'should contain the correct resources' do
        is_expected.to contain_class('letsencrypt::install').with(install_method: 'vcs')
      end
    end
  end

  context 'on EL7 operating system' do
    let(:facts) { { osfamily: 'RedHat', operatingsystemrelease: '7.2', path: '/usr/bin' } }
    let(:params) { { email: 'foo@example.com' } }

    describe 'with defaults' do
      it { is_expected.to compile }

      it 'should contain the correct resources' do
        is_expected.to contain_class('epel').that_comes_before('Package[letsencrypt]')
        is_expected.to contain_class('letsencrypt::install').with(install_method: 'package')
      end
    end
  end

  context 'on Debian 8 operating system' do
    let(:facts) { { osfamily: 'Debian', operatingsystem: 'Debian', operatingsystemrelease: '8.0', path: '/usr/bin' } }
    let(:params) { { email: 'foo@example.com' } }

    describe 'with defaults' do
      it { is_expected.to compile }

      it 'should contain the correct resources' do
        is_expected.to contain_class('letsencrypt::install').with(install_method: 'vcs')
      end
    end
  end

  context 'on Debian 9 operating system' do
    let(:facts) { { osfamily: 'Debian', operatingsystem: 'Debian', operatingsystemrelease: '9.0', path: '/usr/bin' } }
    let(:params) { { email: 'foo@example.com' } }

    describe 'with defaults' do
      it { is_expected.to compile }

      it 'should contain the correct resources' do
        is_expected.to contain_class('letsencrypt::install').with(install_method: 'package')
      end
    end
  end

  context 'on Ubuntu 14.04 operating system' do
    let(:facts) { { osfamily: 'Debian', operatingsystem: 'Ubuntu', operatingsystemrelease: '14.04', path: '/usr/bin' } }
    let(:params) { { email: 'foo@example.com' } }

    describe 'with defaults' do
      it { is_expected.to compile }

      it 'should contain the correct resources' do
        is_expected.to contain_class('letsencrypt::install').with(install_method: 'vcs')
      end
    end
  end

  context 'on Ubuntu 16.04 operating system' do
    let(:facts) { { osfamily: 'Debian', operatingsystem: 'Ubuntu', operatingsystemrelease: '16.04', path: '/usr/bin' } }
    let(:params) { { email: 'foo@example.com' } }

    describe 'with defaults' do
      it { is_expected.to compile }

      it 'should contain the correct resources' do
        is_expected.to contain_class('letsencrypt::install').with(install_method: 'package')
      end
    end
  end
end
