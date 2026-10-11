# Matrix

**Chatten über Matrix**

Echter Matrix-Client: bei matrix.org oder deinem eigenen Server anmelden, Räume öffnen, Nachrichten schreiben. Verschlüsselte Räume folgen.

## Das kann die App

- Anmelden bei matrix.org oder eigenem Server
- Räume und Direktnachrichten
- Nachrichten senden und empfangen in Echtzeit

## Läuft auf

iOS 6.1.6 · gejailbreakter iPod touch

Braucht: Matrix-Konto

## Installieren

Am einfachsten über den **[Reboot Appstore](https://github.com/SecondTrack/reboot)** direkt auf dem iPod.
Von Hand: das `.deb` aus dem [neuesten Release](https://github.com/SecondTrack/matrix/releases/latest) laden und mit `dpkg -i` installieren, danach `uicache`.

## Selbst bauen

Mit [Theos](https://theos.dev) (iOS-SDK mit armv7):

```sh
make package
```

## Teil von Reboot

Diese App gehört zu **Reboot** von [Second Track](https://secondtrack.de) – neue Apps für alte iPods.
Alle Apps: [SecondTrack](https://github.com/SecondTrack).

## Lizenz

GPL-3.0 – siehe [LICENSE](LICENSE). Mitgelieferte Bibliotheken unter `vendor/` behalten ihre eigenen Lizenzen.
Nicht mit Apple verbunden. iPod ist eine Marke von Apple Inc.
