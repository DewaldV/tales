+++
title = 'Watching my cats from anywhere with Tailscale'
date = 2026-03-28T09:00:00Z
draft = true
tags = ['tailscale', 'networking', 'raspberry-pi', 'homelab', 'privacy']
+++

I have a couple of cameras around the house to keep an eye on the cats when I'm away. The ones I use are [Reolink E1 Zoom](https://reolink.com/product/e1-zoom/) cameras, which were noticeably cheaper when I first bought them. They work entirely offline - no cloud account required, no mandatory app sign-in, just a camera on the local network. The problem is that "on the local network" is the operative phrase. As soon as you leave the house, you lose access unless you involve Reolink's cloud relay, which I'd rather not do.

This post covers how I set up a [Raspberry Pi 5](https://www.raspberrypi.com/products/raspberry-pi-5/) as a Tailscale subnet router to bridge that gap. The camera stays local-only, and I can reach it from my phone anywhere.

## The camera

The Reolink E1 Zoom is a pan-and-tilt Wi-Fi camera. The key properties that made it attractive:

- **Fully offline capable.** It doesn't need to phone home to work. Once it's on your local network, it operates without any cloud dependency.
- **Local web interface.** The camera serves a web UI at its local IP address (`http://192.168.1.x`) for configuration and live viewing from a browser.
- **Direct IP access from the Reolink app.** The mobile app can connect to the camera via a plain IP address on the local network, no cloud relay involved.
- **NVR-compatible.** If the setup grows, the camera can be integrated into a network video recorder later without replacing hardware.

The tradeoff for all this is that remote access requires you to either use Reolink's P2P cloud service, poke holes in your firewall, or find another way. We're going to do the latter.

*[screenshot: camera settings page showing local IP address]*

## Setting up the Reolink app on the local network

Before worrying about remote access, the first step is getting the app talking to the camera directly on the local Wi-Fi network.

With your phone connected to the same Wi-Fi network as the camera, open the Reolink app and add a new device. Choose the option to add by IP address rather than scanning a QR code or using Reolink's cloud discovery. Enter the camera's local IP address - you can find this in your router's DHCP client list, or in the camera's web interface under network settings. The default credentials are printed on the camera label; change them during setup.

*[screenshot: Reolink app "Add Device" screen showing IP address entry field]*

Once added, the app connects directly to the camera over the local network. Live view, playback, and settings all work without any cloud involvement. This is the baseline we want to preserve when we're away from home.

*[screenshot: Reolink app live view of the camera feed]*

## Tailscale and subnet routing

[Tailscale](https://tailscale.com/) is a VPN built on WireGuard that creates a private overlay network (a "tailnet") between your devices. [Getting started](https://tailscale.com/kb/1017/install/) is quick - install the client on your devices, sign in, and they can reach each other by a stable IP or hostname regardless of where they are.

The feature we care about here is [subnet routing](https://tailscale.com/kb/1019/subnets/). A subnet router is a tailnet node that advertises a local IP range to the rest of the tailnet. Other devices on the tailnet can then route traffic to that range through the subnet router, even for hosts that don't have Tailscale installed. The camera doesn't need to know anything about Tailscale - it just sits on the local network as normal. The Pi acts as the bridge.

## Setting up the Raspberry Pi as a subnet router

The Pi is running Raspberry Pi OS. Install Tailscale using the official install script:

```console
curl -fsSL https://tailscale.com/install.sh | sh
```

Subnet routing requires IP forwarding to be enabled on the Pi. Create a sysctl config file to make it persistent:

```console
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

Now bring Tailscale up and advertise the local subnet. In this example the home network is `192.168.1.0/24` - substitute your own subnet if it's different:

```console
sudo tailscale up --advertise-routes=192.168.1.0/24
```

The first time you run this, it will print a URL to authenticate the device with your Tailscale account. Open it in a browser, sign in, and the Pi will appear in your [Tailscale admin console](https://login.tailscale.com/admin/machines).

The advertised subnet route needs to be approved before it becomes active. In the admin console, find the Pi, open its route settings, and enable the `192.168.1.0/24` route. Tailscale won't automatically accept subnet advertisements without this step.

*[screenshot: Tailscale admin console showing the Pi with subnet route approval toggle]*

With the route approved, any device on your tailnet can reach `192.168.1.0/24` through the Pi.

## Connecting from outside the network

With Tailscale installed on your phone and connected to the tailnet, turn off Wi-Fi so you're on mobile data only. Open the Reolink app and connect to the camera using the same local IP address as before, `192.168.1.x`. The app has no idea it's no longer on the local network - the subnet router handles the routing transparently.

*[screenshot: Reolink app live view working over mobile data via Tailscale]*

The camera feed comes through the Pi over the encrypted WireGuard tunnel that Tailscale manages. Latency is slightly higher than on the local network, but for watching cats wander around the house it's perfectly fine.

## Locking it down

At this point the setup is working: the camera is local-only, there's no cloud relay involved, and access from outside the house goes through the tailnet. The last thing worth doing is explicitly disabling the camera's built-in P2P remote access feature, so there's no accidental route to the device from the open internet.

Reolink provides [instructions for disabling P2P remote access](https://support.reolink.com/articles/4404480742425-How-to-Disable-Remote-Access-P2P-on-Reolink-Device/) on their support site. The setting is in the camera's web interface under network settings. Once disabled, the only way to reach the camera remotely is through the tailnet.

To summarise what's in place: the camera operates entirely on the local network with no cloud dependency, the Reolink app connects to it directly by IP, and a Raspberry Pi running as a Tailscale subnet router makes that same local IP reachable from anywhere on the tailnet. The camera itself has no awareness of any of this and needs no configuration beyond its normal local network setup.
