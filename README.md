# fail2ban-cloudflare - for Cloudflare API V4

Integrate Fail2ban with Cloudflare API (V4) to mitigate HTTP flooding and brute forcing using Nginx.

Requirements:

1. Nginx
2. Fail2ban
3. A Cloudflare account
4. Ruby 

### Get your Cloudflare API Key

1. Signup to Cloudflare: https://www.cloudflare.com/a/sign-up

2. Go to https://www.cloudflare.com/a/account/my-account and select `View API Key`.

3. Setup your site(s) to use Cloudflare

### Configure Fail2ban

1. Install `Fail2ban` on the server running Nginx and Roboo.

2. Add the `cloudflare.conf` file to your `action.d` dir.

3. Edit the `cloudflare_api_manager.rb` file and set your `CLOUDFLARE_USERNAME` and `CLOUDFLARE_API_KEY` (line 8 and 9).

4. Optional add any proxy information if you need to access Cloudflare via a proxy server (line 15 to 18).

5. Add the following `banaction` to your `jail.conf` file (or any other jails):

    ```
    banaction = cloudflare
    ```

6. Add the `cloudflare_api_manager.rb` script to a location accessible to the `fail2ban` user and set appropriate permissions. Remember that your Cloudflare API keys are stored in this script so handle with care!  

7. Verify that an IP is added to your Cloudflare firewall by banning an IP:

    ```
    /path/to/ruby /path/to/cloudflare_api_manager.rb ban 1.2.3.4
    ```

8. Verify that the IP is removed from your Cloudflare firewall by unbanning the IP:

    ```
    /path/to/ruby /path/to/cloudflare_api_manager.rb unban 1.2.3.4
    ```

9. Restart `Fail2ban`

It might be a good idea to whitelist the IP range of Cloudflare in `Fail2ban` using the `ignoreip` section. A current list of the IP ranges of Cloudflare can be found here: https://www.cloudflare.com/ips/

NOTE: Not tested with IPv6. 
