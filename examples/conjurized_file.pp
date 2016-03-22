conjurized_file { 'test':
  ensure  => present,
  path    => '/tmp/conjurized_file',
  content => "Hello world. Your secret is <%= conjur_variable('Puppet/production/foo') %>\n",
}
