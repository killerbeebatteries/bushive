# Bus Hive

A while ago we had this idea that we'd setup this mesh network using buses (as in public transport) to distribute information around to the nodes to provide important information to clients (connected to the node via wifi).

The buses would sync with a controller node when they were parked up at the depot. Then, when they went on their routes, they'd replicate to nodes that lived at the bus stops.

End users would then connect to these nodes to retrieve data.

An example use case would be relaying weather warnings from the BOM.

An extension of this idea, outside of using buses, would be that you have a node sitting at a floodway collecting data on the water depth. It then relays this information to any receiving node going past (so a car driving past).

That data is then relayed back to an authorative endpoint.

# Architecture

The considerations of the different components and the technologies chosen to provide the required functionality is based on:
- Keep it simple
- Use tech that is well supported and well tested.
- Don't reinvent things.
- Try not to have too much overhead, but try and find that balance between minimum power/resource consumption and maintainability.

## Programming languages

Considering using Golang for gluing everything together, as it seems like a good fit for having a low resource consumption service running. It's compiled, so we can either run stand-alone binaries or be built into an OCI container to be distributed via registries.

I am going to assume we'll end up with a bash script for initially provisioning a node.

## Hardware

Maybe target Raspi for now.

## Services

### Wifi

We want to be able to:
- Scan for other nodes and connect to them.
- Serve as an AP for other nodes and end-users.

Not sure if utilising a mesh network would have a lot of benefit here... I think if end-users could easily connect to it.

Thinking of the [Freifunk](https://freifunk.net/en/what-is-it-about/) firmware running on WRT routers... a client could connect and NAT through the network, or another WRT could connect and become a node in the network.

I suppose the thing to identify here is that there are two types of network connections we need to consider:
1. One node needing a way of communicating with another node.
2. End users that will have a device such as a phone or laptop to retrieve data from the node.

### DNS

Run an internal DNS to allow for easily connecting to services.

- user.hive.the-mesh.org
- sys.hive.the-mesh.org
- data.hive.the-mesh.org


### Web

Information for end users will be provided via a web frontend. Thinking a Golang served webserver will do the trick for now.

### TLS certs

The system components and the data being relayed across the nodes could be considered public or open, so the requirement for TLS encrpyted communication on the web services isn't strictly required - except for the case where some clients won't accept plain-text http... in this case we'll need something like a Lets Encrypt cert to be distributed.

 There's going to be some considerations to be made here as we probably don't want to keep private keys in the registry in plain-text... even though they'll be available on the nodes... which are going to be physically accessible.

This probably leads onto a greater consideration of authenticating the data being hosted. I would think that things like a builtin could just have a checksum provided with it that can be verified against the source data.

We will probably need a way of verifying nodes (and the contents) so someone running a rogue node providing weather information saying it's going to snow in the tropics can be proven to be misleading.

### GPG

Not sure if digital signatures will be required initially? Maybe signed commits for the system and data git repos? ... along with the OCI registries.

## Sync

Nodes need to have a way of being able to determine:
- Do I have data?
- Is my data up to date?
- If I am connected to another node, do I have more recent data? If so, make it available for that node to replicate.

### Git

Git has been used for a fair while now as a tool for version control and distributing data based on various versions of data. It seems a good fit for being able to authoratively distribute information by providing authenticated and verified data repositories.

#### System

A repo that's used to coordinate updates to the nodes themselves.

#### Relay data

One or more repos that are used for providing data for replication to the nodes.

## Orchestration

The [k3s](https://k3s.io/) project looks interesting. Kubernetes seems like a good fit for managing the components of our system.

### Flux CD

We're using git already, so a GitOps tool sit between Kubernetes and the system git repo makes sense. It might be a little overkill, so we'll need to test this out.

#### Kubernetes manifests

Host our different components via OCI containers:
- replication
- web serving
- collection

#### Registry
- retrieve signed OCI containers

## Modes

Nodes will serve metadata to inform their neighbours and other entities that may be curious as to what services and data versions the node is providing.

### serving

Serving web data to end users.

Serving replication data to other nodes

### collecting

Collecting data from inputs. So this could be metrics that are being provided by different local interfaces (USB/serial etc).

### relaying

Relaying is kind of like serving, except the node might just be functioning as an intermeditary to relay data from one node to another.

The idea here is you might have someone that's running an app on their phone that's either a passively connecting to nodes and retreiving data (that it's been configured to listen for) or actively doing it when a user turns up and wants to collect certain data from a node (so a node at a floodway, just say).

This data is collected, then can be relayed back to a target endpoint, that can either publish the information back to the network, or maybe published to a website. So in the case of fllodwater info, it'd update a website with the latest retrieved data.

## Authentication

### GPG

Each (trusted) node will have a GPG key that it will use to sign data. We can use this as a way of verifying the originating node of the data. 

This might get tricky as it wouldn't be that hard to "borrow" a node, copy it's keys, then setup your own node and sign data with those keys... something to think about.

You might have observed that there is a bit of concern over verification. This is one of those, "consider it early on, but don't get too caught up in overthinking things" sort of situations.

Trying to keep the system as open as possible, but also trying to make sure the information retrieved and replicated is authentic and verified.

It's going to be a weakness of this kind of network, but some attempts at security seem reasonable.

# Development plans

Well, there's a lot of moving parts here. I think the first bit to tackle is getting a software version two or more nodes working on a local network.

Test out:
- Bootstapping a node
- System repo replication and state reconciliation.
- Data repo replication and publication (both from an origin)

Then we can start introducing the real-world elements like Wifi and nodes that come and go from the network.
- How do we handle intermittent links or limited time replication?

## VMs and containers

I think for a development environment we can use VMs (Vagrant?) to create our provisioning script. 

Then we can start building the containers that will be used by the Kubernetes cluster.

As a thought, maybe our first data repo could be a blog that contains the TODO and a bit of a journal on where we're at with things. It'll give us data to replicate, whilst (hopefully) providing a helpful timeline of what we're doing.
