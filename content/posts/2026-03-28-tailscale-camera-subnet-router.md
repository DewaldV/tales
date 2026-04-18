+++
title = 'Watching my cats from anywhere with Tailscale'
date = 2026-03-28T09:00:00Z
draft = true
tags = ['tailscale', 'networking', 'raspberry-pi', 'homelab', 'privacy']
+++

I have a couple of cameras around the house to keep an eye on the cats when I'm away. The ones I use are [Reolink E1 Zoom](https://reolink.com/product/e1-zoom/) cameras. They work entirely offline, no cloud account required, no mandatory app sign-in, just a camera on the local network. The limitation is obvious once you leave the house. If the camera is only reachable on `192.168.1.x`, remote access usually means either handing that job to Reolink's relay service or exposing something on your own network. I wanted neither.

What I ended up with is simple: the cameras stay local-only, a [Raspberry Pi 5](https://www.raspberrypi.com/products/raspberry-pi-5/) advertises the home subnet into my tailnet, and the Reolink app continues talking to the camera by its normal LAN address even when I'm on mobile data.

## Why this camera works well for it

I picked the hardware first, because the whole setup depends on the camera not insisting on a cloud control plane.

The Reolink E1 Zoom is a pan-and-tilt Wi-Fi camera, but the important part here is not the camera feature list. It is that the device still behaves like a normal host on a normal LAN. It serves a web UI on its local IP, the mobile app can connect to it directly by IP address, and none of that requires a vendor account once the initial local setup is done.

That is the whole reason this approach works. The camera does not need to know anything about Tailscale, NAT traversal, or remote access. It just needs to stay reachable on the home subnet.

*[screenshot: camera settings page showing local IP address]*

## Getting the app working locally first

I set up the local path first, because the remote path is just an extension of it.

With the phone connected to the same Wi-Fi network as the camera, open the Reolink app and add the device by IP address rather than QR code or cloud discovery. The IP can come from your router's DHCP lease list or from the camera's own network settings page. The default credentials are printed on the camera label, and are worth changing immediately.

*[screenshot: Reolink app "Add Device" screen showing IP address entry field]*

Once added, the app talks straight to the camera over the LAN. Live view, playback, and settings work without any cloud involvement. That is the baseline worth preserving when away from home.

*[screenshot: Reolink app live view of the camera feed]*

## Tailscale and subnet routing

[Tailscale](https://tailscale.com/) is a VPN built on WireGuard that creates a private overlay network (a "tailnet") between your devices. [Getting started](https://tailscale.com/kb/1017/install/) is quick - install the client on your devices, sign in, and they can reach each other by a stable IP or hostname regardless of where they are.

The feature that matters here is [subnet routing](https://tailscale.com/kb/1019/subnets/). A subnet router is a tailnet node that advertises a local IP range to the rest of the tailnet. Other devices on the tailnet can then route traffic to that range through the subnet router, even for hosts that do not have Tailscale installed. The camera stays exactly as it was, on the local network, and the Pi becomes the bridge.

## Turning the Pi into the bridge

I used a Raspberry Pi 5 running Raspberry Pi OS, but any always-on Linux box on the home network would do.

Install Tailscale using the official install script:

```console
curl -fsSL https://tailscale.com/install.sh | sh
```

Subnet routing requires IP forwarding. Create a sysctl drop-in so the setting survives reboot:

```console
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

Now bring Tailscale up and advertise the local subnet. In this example the home network is `192.168.1.0/24`, substitute your own subnet if it differs:

```console
sudo tailscale up --advertise-routes=192.168.1.0/24
```

The first run prints a URL to authenticate the device with your Tailscale account. After signing in, the Pi shows up in the [Tailscale admin console](https://login.tailscale.com/admin/machines).

The advertised route then needs to be approved before it becomes active. In the admin console, find the Pi, open its route settings, and enable the `192.168.1.0/24` route. Tailscale does not automatically accept subnet advertisements without that approval step.

*[screenshot: Tailscale admin console showing the Pi with subnet route approval toggle]*

With the route approved, any device on your tailnet can reach `192.168.1.0/24` through the Pi.

## Using it away from home

I tested it by turning off Wi-Fi on my phone and forcing it onto mobile data. With Tailscale connected, the Reolink app could still reach the camera on the same `192.168.1.x` address as before. The app does not know it has left the local network, the subnet router handles the path transparently.

*[screenshot: Reolink app live view working over mobile data via Tailscale]*

The camera feed comes through the Pi over the encrypted WireGuard tunnel that Tailscale manages. Latency is slightly higher than on the local network, but for watching cats wander around the house it's perfectly fine.

## Disabling the vendor remote path

I disabled the vendor remote-access path last, once the Tailscale path was working end to end.

At this point the setup is already doing the right thing: the camera stays local-only, there is no cloud relay involved, and access from outside the house goes through the tailnet. The last step is to explicitly disable the camera's built-in P2P remote access feature so there is no accidental path left through Reolink's infrastructure.

Reolink provides [instructions for disabling P2P remote access](https://support.reolink.com/articles/4404480742425-How-to-Disable-Remote-Access-P2P-on-Reolink-Device/) on their support site. The setting is in the camera's web interface under network settings. Once disabled, the only way to reach the camera remotely is through the tailnet.

## What is actually in place

The camera operates entirely on the local network with no cloud dependency. The Reolink app connects to it directly by IP. A Raspberry Pi running Tailscale advertises the home subnet into the tailnet, which makes that same private IP reachable from any authenticated device I own. The camera itself has no awareness of any of this and needs no special integration beyond its normal LAN setup.
