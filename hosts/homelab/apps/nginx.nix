{ config, lib, pkgs, ... }:
{
	config = {
		services.nginx = {
			enable = true;
			recommendedProxySettings = true;
            recommendedTlsSettings = true;
            recommendedGzipSettings = true;
            recommendedOptimisation = true;
			virtualHosts."jellyfin.jdiggity.me" = {
				enableACME = true;
				forceSSL = true;
				extraConfig = 
					"add_header X-Frame-Options \"SAMEORIGIN\";" +
					"client_max_body_size 20M;" +
					"add_header X-Content-Type-Options \"nosniff\";" +
					"add_header Permissions-Policy \"accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()\" always;" +
					"add_header Content-Security-Policy \"default-src https: data: blob: ; img-src 'self' https://* ; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; frame-ancestors 'self'\";";

				locations."/" = {
					proxyPass = "http://localhost:8096";
					extraConfig = 
						"proxy_buffering off;";
				};

				locations."/socket" = {
					proxyPass = "http://localhost:8096";
					proxyWebsockets = true;
				};
			};
		};
		security.acme = {
			acceptTerms = true;
			defaults.email = "joseph.diragi@icloud.com";
        };
        networking.firewall.allowedTCPPorts = [ 80 443 ];
        networking.firewall.allowedUDPPorts = [ 80 443 ];
	};
}
