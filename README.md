nagios-check-spf-record-match
=============================

A Nagios check for monitoring the state of SPF records across multiple domains

    Usage: check_spf_record_match [options]
            --domains domain,[domain]    which domains do you wish to report on?
            --debug                      enable debug mode
        -h, --help                       help

Configuration
-------------

    define command{
      command_name  check_spf_record_match
      command_line  $USER1$/check_spf_record_match.rb --domains '$ARG1$'
      }
    
    define service{
      use                             generic-service
      host_name                       spf_check
      service_description             SPF Record Match
      check_command                   check_spf_record_match!domain1.com,domain2.com!
    }


Notes:
* For our purposes, it supports only SPF records. It could be modified to support DMARC records also if there's interest.
* It supports only TXT records. Ruby doesn't support the SPF rr type, and since the use of it is deprecated anyway I didn't add that functionality.
