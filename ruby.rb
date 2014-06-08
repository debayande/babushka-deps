dep 'ruby trunk.src' do
  requires_when_unmet 'build tools', 'bison.managed', 'readline headers.managed'
  source 'git://github.com/ruby/ruby.git'
  provides 'ruby == 1.9.3.dev', 'gem', 'irb'
  configure_args '--disable-install-doc', '--with-readline-dir=/usr'
end

dep 'ruby.src', :version, :patchlevel do
  if patchlevel.set? && patchlevel[/^p/].nil?
    unmeetable! "patchlevel must start with 'p'."
  end
  def download_version
    patchlevel.set? ? "#{version}-#{patchlevel}" : version
  end
  def specified_ruby_version
    # If the patchlevel isn't set, allow any patchlevel of the given version.
    patchlevel.set? ? "ruby == #{version}#{patchlevel}" : "ruby ~> #{version}p0"
  end
  def version_group
    version.to_s.scan(/^\d\.\d/).first
  end
  def check_exts *ext_names
    ext_names.each {|ext_name|
      log_shell("checking for #{ext_name}", %Q{./ruby -e 'require "#{ext_name}"'}).tap {|result|
        # TODO: this shouldn't be called from the meet{} block.
        unmeetable! "The ruby built without #{ext_name} support." unless result
      }
    }
  end
  version.default!('2.0.0')
  patchlevel.default!('p247')
  requires_when_unmet [
    'curl.lib',
    'openssl.lib',
    'readline.lib',
    'yaml.lib',
    'zlib.lib'
  ]
  source "ftp://ftp.ruby-lang.org/pub/ruby/#{version_group}/ruby-#{download_version}.tar.gz"
  provides specified_ruby_version, 'gem', 'irb'
  configure {
    log_shell "configure", "./configure --prefix=#{prefix} --disable-install-doc"
  }
  build {
    log_shell "build", "make -j#{Babushka.host.cpus}"
    check_exts 'openssl', 'psych', 'readline', 'zlib'
  }
  postinstall {
    # The ruby <1.9.3 installer skips bin/* when the build path contains a dot-dir.
    shell "cp bin/* #{prefix / 'bin'}", :sudo => Babushka::SrcHelper.should_sudo?
  }
end
