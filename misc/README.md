# iOS setup

iOS tests are started by one user running parallel_calabash, which internally runs the tests in parallel using test users to keep the processes separate. This requires set-up.

The config file is follows:

    {
      USERS: [ 'tester1', 'tester2', 'tester3' ],
      PASSWORD: 'testuserspassword', # for autostart_test_users.app and/or setup_ios_host
      INIT: 'source "$HOME/.rvm/scripts/rvm"',
      # You only need to specify the port if the default clashes for you. Simulators start sequentially from this.
      # CALABASH_SERVER_PORT: 3800,
      # You only need to set this if you want to run autostart_test_users and the default 6900 clashes with something.
      # VNC_FORWARD: 6900,
      # Omit 'DEVICES' entirely if you're only testing on simulators.
      # DEVICES: [
      no_DEVICES_today_thankyou: [
        {
          NAME: 'ios-iphone5c-tinkywinkie (8.4.1)',
          DEVICE_TARGET: '23984729837401987239874987239',
          DEVICE_ENDPOINT: 'http://192.168.126.206:37265'
        },
        {
          NAME: 'ios-iphone6plus-lala (8.4)',
          DEVICE_TARGET: 'c987234987983458729375923485792345',
          DEVICE_ENDPOINT: 'http://192.168.126.205:37265',
        },
        {
          NAME: 'ios-iphone6plus-dipsy (8.4.1)',
          DEVICE_TARGET: '98723498792873459872398475982347589',
          DEVICE_ENDPOINT: 'http://192.168.126.207:37265',
        }
      ]
    }

You will probably want two configuration files, one for running from a build for simulators, one for running from a build for devices. It is convenient to call them .parallel_calabash.iphoneos and .parallel_calabash.iphonesimulator so you can select between them based on your choice of build sdk parameter.

Both simulator and device configurations have a list called USERS - you can share the users if you won't be testing devices and simulators at the same time.

Testing on simulators requires that all the test users are logged in to a graphical desktop. Running the autostart_test_users app will do this - you can make that a step in your build script or in your continuous integration client script. (The script was designed to be run at login by the main user, but there were timing issues with the port forwarding that make this unreliable.)

## Set up

Firstly, you need to be able to log in remotely to test machines via ssh: enable Settings > Sharing > Remote Login > Allow access for main account, if not already permitted by Remote Management. If you are testing on simulators, you also need to enable Settings > Sharing > Screen Sharing for main account, if not already permitted by Remote Management.

The misc/setup_ios_host script will try to set up a remote machine for running with simulators:
* copies the auto-login app to /Applications, copies the config file, and authorises the app to use UI Automation.
* creates accounts for each user in USERS, all having PASSWORD.
* ensures the main user has an ssh key, and copies that to each test user's .ssh/authorized_keys.
* soft-links each test user's ~/.rvm to the main user's ~/.rvm on the presumption that you're using .rvm for ruby.

If you only want to test on devices, use the simulator set-up as above to create the users, but use your .parallel_calalabash.iphoenos file instead when running.

