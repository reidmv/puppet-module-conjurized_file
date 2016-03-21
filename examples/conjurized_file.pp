conjurized_file { 'test':
  ensure       => present,
  path         => '/tmp/conjurized_file',
  content      => "Hello world. Your secret is \$foo.\n",
  variable_map => { 'foo' => '!var Puppet/production/foo' },
}
