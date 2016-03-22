require 'puppet/type/file/owner'
require 'puppet/type/file/group'
require 'puppet/type/file/mode'
require 'puppet/util/checksums'

Puppet::Type.newtype(:conjurized_file) do
  @doc = "Based on a template containing Conjor tokens ensures that a file
    exists and is correctly and up-to-date conjurized.
    example:
      conjurized_file { '/tmp/file':
        path    => '/tmp/file',             # Optional. If given it overrides the resource name
        owner   => 'root',                  # Optional. Default to undef
        group   => 'root',                  # Optional. Default to undef
        mode    => '0644'                   # Optional. Default to undef
        content => template('mod/foo.erb'), # Pre-conjurization template content
      }
  "
  ensurable do
    defaultvalues

    defaultto { :present }
  end

  def exists?
    self[:ensure] == :present
  end

  newparam(:name, :namevar => true) do
    desc "Resource name"
  end

  newparam(:path) do
    desc "The output file"
    defaultto do
      resource.value(:name)
    end
  end

  newparam(:owner, :parent => Puppet::Type::File::Owner) do
    desc "Desired file owner."
  end

  newparam(:group, :parent => Puppet::Type::File::Group) do
    desc "Desired file group."
  end

  newparam(:mode, :parent => Puppet::Type::File::Mode) do
    desc "Desired file mode."
  end

  newparam(:backup) do
    desc "Controls the filebucketing behavior of the final file and see File type reference for its use."
    defaultto 'puppet'
  end

  newparam(:replace) do
    desc "Whether to replace a file that already exists on the local system."
    defaultto true
  end

  newparam(:validate_cmd) do
    desc "Validates file."
  end

  newparam(:content) do
    desc "Pre-conjurization file content (Conjur template)"
  end

  # Inherit File parameters
  newparam(:selinux_ignore_defaults) do
  end

  newparam(:selrange) do
  end

  newparam(:selrole) do
  end

  newparam(:seltype) do
  end

  newparam(:seluser) do
  end

  newparam(:show_diff) do
  end
  # End file parameters

  # Autorequire the file we are generating below
  autorequire(:file) do
    [self[:path]]
  end

  def conjurized_content
    # The conjur libraries depend on either a $HOME environment variable being
    # set, or having this override. In order to prevent the libraries from
    # exploding, set this var before attempting to do anything with conjur. For
    # good form we'll reset it to the original value when we're done.
    original_conjurrc = ENV['CONJURRC']
    ENV['CONJURRC'] = '/dev/null'

    unless Puppet.features.conjur?
      raise Puppet::Error "Puppet must have conjur feature working to use #{self.class.name.to_s} type"
    end

    # DO CONJURIZE MAGIC HERE
    # Should return a version of the content parameter that has been run over
    # by Conjur to replace any in-template keys with the actual secrets.
    def conjur_variable(key)
      unless @api
        Conjur::Config.load
        Conjur::Config.apply
        @api = Conjur::Authn.connect nil, noask: true
      end
      result = @api.variable key
      result.value
    end

    template = @parameters[:content].value
    rendered = ERB.new(template).result(binding)

    # Reset the environment variable we had to hack earlier.
    ENV['CONJURRC'] = original_conjurrc

    rendered
  end

  def generate
    file_opts = {
      :ensure  => self[:ensure] == :absent ? :absent : :file,
    }

    [ :path,
      :owner,
      :group,
      :mode,
      :replace,
      :backup,
      :selinux_ignore_defaults,
      :selrange,
      :selrole,
      :seltype,
      :seluser,
      :show_diff
    ].each do |param|
      unless self[param].nil?
        file_opts[param] = self[param]
      end
    end

    [Puppet::Type.type(:file).new(file_opts)]
  end

  def eval_generate
    content = conjurized_content

    if !content.nil? and !content.empty?
      catalog.resource("File[#{self[:path]}]")[:content] = content
    end

    [ catalog.resource("File[#{self[:path]}]") ]
  end
end
