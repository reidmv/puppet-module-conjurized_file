require 'puppet/util/feature'

Puppet.features.add(:conjur, libs: ['conjur/config', 'conjur/authn'])
