# 6rd on MikroTik RouterOS

For detailed information about this script, refer to
[the corresponding blog post][blog-post-url].

[blog-post-url]: https://fwmotion.com/blog/networking/2021-08-16-6rd-on-mikrotik-routeros/

## Installation

```routeros
/tool fetch https://raw.githubusercontent.com/FwMotion/6rd-on-routeros/master/6rd-on-routeros.rsc output=file dst-path=6rd-on-routeros.rsc
/import file=6rd-on-routeros.rsc
/file remove 6rd-on-routeros.rsc
```

## Manual Run

```routeros
/system script run script-6rd-centurylink
```

## Scheduled Run

```routeros
/system scheduler add name=scheduler-6rd-centurylink interval=5m on-event=script-6rd-centurylink
```
