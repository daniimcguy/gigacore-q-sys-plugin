<!-- PROJECT Header -->
<div align="center">
  <h3 align="center">Luminex GigaCore Q-SYS Plugin</h3>

  <p align="center">
    A plugin for monitoring and controlling GigaCore network switches from Q-SYS
  </p>
</div>

<!-- Description -->
## Description
This is an open-source Q-SYS plugin for controlling and monitoring
[Generation 2](https://support.luminex.be/portal/en/kb/articles/gigacore-generation-2-devices)
[Luminex](https://www.luminex.be/) GigaCore switches from
[Q-SYS](https://www.qsys.com/).

---

## LLDP neighbors

The plugin reads the switch's LLDP neighbors and shows, for each port, the
device on the other end: its name, its description (model and firmware), the
port it uses and its management IP address.

- **Neighbor panel**: click a port on the chassis to open its panel; click the
  same port again, or **Close**, to close it. **→ Legend** writes the neighbor
  as the port legend: its name, then ` p` and its port when that is a number
  (`Stage Left p5`), at most 16 characters (a long name is shortened so the
  port number stays).
- **Neighbors tab**: one row per port with its neighbor's name, description,
  port and IP address.
- **UCI**: for the panel to work on a UCI, place the `Port.Card N` controls
  together with `zLldp.Panel`, `zLldp.Panel To Legend` and `zLldp.Panel Close`.

---

## Download & Updates

The **latest stable version** of the plugin is always available on the **Releases** page.

**Download the latest release:**
https://github.com/luminex-lce/gigacore-q-sys-plugin/releases/latest

### How to update
1. Download the `.qplug` file attached to the **latest release**
2. Import the plugin into Q-SYS Designer
3. Replace the existing plugin if prompted

The version number is indicated by the **release tag** (e.g. `v2.0.0`).

---

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this plugin better, please fork the repo and create a pull request. Alternatively, use the **Issues** functionality to request new features.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.
