Puppet::Type.type(:conjurized_file).provide(:ruby) do
  confine feature: :conjur

  def conjurized_content
    Conjur::Config.load
    Conjur::Config.apply

    conjur = Conjur::Authn.connect nil, noask: true

    # DO CONJURIZE MAGIC HERE
    # Should return a version of the content parameter that has been run over
    # by Conjur to replace any in-template keys with the actual secrets.
    @resource[:content]
  end

end
