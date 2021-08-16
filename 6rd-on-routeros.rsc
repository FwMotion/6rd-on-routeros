/system script
add dont-require-permissions=no name=script-6rd-centurylink \
    policy=read,write source="# Configuration\
    \n:local ipv4interface \"pppoe-wan-centurylink\"\
    \n:local ipv6interfaceWan \"6rd-wan-centurylink\"\
    \n:local ipv6interfaceLanArray {\"bridge1.301\";\"bridge1.306-private-ipv6\
    \";\"bridge1.401-public-access\"}\
    \n:local ipv6addrcomment \"managed-by-6rd\"\
    \n\
    \n:local ipv6gatewayDestination \"2000::/3\"\
    \n\
    \n:local ipv6prefix \"2602:\"\
    \n:local ipv6prefixLen 24\
    \n\
    \n:local ipv6pool \"pool-6rd-centurylink\"\
    \n:local ipv6suffixLanPool \"00::\"\
    \n:local ipv6suffixLanPoolDelta 8\
    \n\
    \n:local ipv6suffixWan \"00::1/64\"\
    \n:local ipv6addressLan \"::1/64\"\
    \n\
    \n:local ipv4border \"205.171.2.64\"\
    \n:local ipv6mtu 1472\
    \n\
    \n# Set up\
    \n:local ipv4address [/ip address get [/ip address find interface=\$ipv4in\
    terface] address]\
    \n:set ipv4address [:pick \$ipv4address 0 [:find \$ipv4address \"/\"]]\
    \n\
    \nif (\$ipv4address=\"\") do={\
    \n  :error \"Error getting IPv4 address\"\
    \n}\
    \n\
    \n# IPv6 6to4 Tunnel\
    \n:local ipv6tunnel [/interface 6to4 find where name=\$ipv6interfaceWan]\
    \n\
    \n:if (\$ipv6tunnel=\"\") do={\
    \n  :log info \"[6rd] Creating tunnel name=\$ipv6interfaceWan\"\
    \n  :put \"[6rd] Creating tunnel name=\$ipv6interfaceWan\"\
    \n  /interface 6to4 add name=\$ipv6interfaceWan local-address=\$ipv4addres\
    s remote-address=\$ipv4border mtu=\$ipv6mtu !keepalive  \
    \n} else={\
    \n  :local oldipv4address [/interface 6to4 get \$ipv6tunnel local-address]\
    \n  :if (\$oldipv4address!=\$ipv4address) do={\
    \n    :log info \"[6rd] Changing tunnel name=\$ipv6interfaceWan from local\
    -address=\$oldipv4address to local-address=\$ipv4address\"\
    \n    :put \"[6rd] Changing tunnel name=\$ipv6interfaceWan from local-addr\
    ess=\$oldipv4address to local-address=\$ipv4address\"\
    \n    /interface 6to4 set \$ipv6tunnel local-address=\$ipv4address\
    \n  }\
    \n}\
    \n\
    \n# IPv4 -> IPv6-style octet function\
    \n:local buildIPv4Octets do={\
    \n  :local ipv4addr [:toip6 (\"1::\" . \$ipv4address)]\
    \n\
    \n  :if (\$ipv4addr=\"\") do={\
    \n    :error \"Error converting IPv4 to IPv6 address\"\
    \n  }\
    \n\
    \n  :local emptyOctet [pick \"\" 1]\
    \n  :local ipv4addrOctetsSetOne \"\"\
    \n  :local ipv4index 3\
    \n  :local ipv4Octet \"\"\
    \n  :for ipv4octetCountOne from=1 to=4 step=1 do={\
    \n    :set ipv4Octet [:pick \$ipv4addr \$ipv4index]\
    \n    :if ((\$ipv4Octet=\$emptyOctet) or (\$ipv4Octet=\":\")) do={\
    \n      :set ipv4addrOctetsSetOne (\"0\" . \$ipv4addrOctetsSetOne)\
    \n    } else={\
    \n      :set ipv4addrOctetsSetOne (\$ipv4addrOctetsSetOne . \$ipv4Octet)\
    \n      :set ipv4index (\$ipv4index + 1)\
    \n    }\
    \n  }\
    \n\
    \n  :local ipv4addrOctetsSetTwo \"\"\
    \n  :set ipv4index (\$ipv4index + 1)\
    \n  :for ipv4octetCountTwo from=1 to=4 step=1 do={\
    \n    :set ipv4Octet [:pick \$ipv4addr \$ipv4index]\
    \n    :if ((\$ipv4Octet=\$emptyOctet) or (\$ipv4Octet=\":\")) do={\
    \n      :set ipv4addrOctetsSetTwo (\"0\" . \$ipv4addrOctetsSetTwo)\
    \n    } else={\
    \n      :set ipv4addrOctetsSetTwo (\$ipv4addrOctetsSetTwo . \$ipv4Octet)\
    \n      :set ipv4index (\$ipv4index + 1)\
    \n    }\
    \n  }\
    \n\
    \n  :return (\$ipv4addrOctetsSetOne . \$ipv4addrOctetsSetTwo)\
    \n}\
    \n:local ipv4addressOctets [\$buildIPv4Octets ipv4address=\$ipv4address]\
    \n\
    \n# IPv4 -> IPv6 prefix function\
    \n:local buildIPv6PrefixFromIPv4 do={\
    \n  :local ipv6pre \$ipv6prefix\
    \n  :local ipv4index 0\
    \n  :local ipv6preHadNonZero true\
    \n  :local ipv4OctetToCopy \"\"\
    \n  :local ipv4ShouldDoCopy false\
    \n  :for ipv6len from=\$ipv6prefixLen to=(\$ipv6prefixLen + 28) step=4 do=\
    {\
    \n    :if ((\$ipv6len % 16)=0) do={\
    \n      :set ipv6pre (\$ipv6pre . \":\")\
    \n      :set ipv6preHadNonZero false\
    \n    }\
    \n    :set ipv4OctetToCopy [:pick \$ipv4addressOctets \$ipv4index]\
    \n    :if (\$ipv4OctetToCopy=\"0\") do={\
    \n      :if (\$ipv6preHadNonZero) do={\
    \n        :set ipv4ShouldDoCopy true\
    \n      } else={\
    \n        :set ipv4ShouldDoCopy false\
    \n      }\
    \n    } else={\
    \n      :set ipv4ShouldDoCopy true\
    \n      :set ipv6preHadNonZero true\
    \n    }\
    \n    :if (\$ipv4ShouldDoCopy) do={\
    \n      :set ipv6pre (\$ipv6pre . \$ipv4OctetToCopy)\
    \n    }\
    \n    :set ipv4index (\$ipv4index + 1)\
    \n  }\
    \n\
    \n  :return \$ipv6pre\
    \n}\
    \n:local ipv6addressPrefix [\$buildIPv6PrefixFromIPv4 ipv6prefix=\$ipv6pre\
    fix ipv6prefixLen=\$ipv6prefixLen ipv4addressOctets=\$ipv4addressOctets]\
    \n\
    \n# IPv6 address pool\
    \n:local ipv6poolPrefix (\$ipv6addressPrefix . \$ipv6suffixLanPool . \"/\"\
    \_. (\$ipv6prefixLen + 32))\
    \n:local ipv6poolPrefixLength (\$ipv6prefixLen + 32 + \$ipv6suffixLanPoolD\
    elta)\
    \n\
    \n:local ipv6poolNumber [/ipv6 pool find where name=\$ipv6pool]\
    \n\
    \n:local ipv6poolChanged false\
    \n\
    \n:if (\$ipv6poolNumber=\"\") do={\
    \n  :log info \"[6rd] Adding IPv6 pool name=\$ipv6pool with prefix=\$ipv6p\
    oolPrefix prefix-length=\$ipv6poolPrefixLength\"\
    \n  :put \"[6rd] Adding IPv6 pool name=\$ipv6pool with prefix=\$ipv6poolPr\
    efix prefix-length=\$ipv6poolPrefixLength\"\
    \n  /ipv6 pool add name=\$ipv6pool prefix=\$ipv6poolPrefix prefix-length=\
    \$ipv6poolPrefixLength  \
    \n} else={\
    \n  :local oldipv6poolPrefix [/ipv6 pool get \$ipv6poolNumber prefix]\
    \n  :if (\$oldipv6poolPrefix!=\$ipv6poolPrefix) do={\
    \n    :set ipv6poolChanged true\
    \n    :log info \"[6rd] Removing IPv6 addresses prior to pool change; pool\
    \_name=\$ipv6pool\"\
    \n    :put \"[6rd] Removing IPv6 addresses prior to pool change; pool name\
    =\$ipv6pool\"\
    \n    /ipv6 address remove [/ipv6 address find where from-pool=\$ipv6pool]\
    \n    :log info \"[6rd] Changing IPv6 pool name=\$ipv6pool from prefix=\$o\
    ldipv6poolPrefix to prefix=\$ipv6poolPrefix prefix-length=\$ipv6poolPrefix\
    Length\"\
    \n    :put \"[6rd] Changing IPv6 pool name=\$ipv6pool from prefix=\$oldipv\
    6poolPrefix to prefix=\$ipv6poolPrefix prefix-length=\$ipv6poolPrefixLengt\
    h\"\
    \n    /ipv6 pool set \$ipv6poolNumber prefix=\$ipv6poolPrefix prefix-lengt\
    h=\$ipv6poolPrefixLength\
    \n  }\
    \n}\
    \n\
    \n# IPv6 address update function\
    \n:local changeIPv6Address do={\
    \n  :local ipv6addr [/ipv6 address find where interface=\$ipv6interface an\
    d comment=\$ipv6comment]\
    \n  :if (\$ipv6addr=\"\") do={\
    \n    /ipv6 address add interface=\$ipv6interface comment=\$ipv6comment ad\
    dress=\$ipv6address advertise=\$ipv6advertise from-pool=\$ipv6pool\
    \n    :local newipv6address [/ipv6 address get [/ipv6 address find where i\
    nterface=\$ipv6interface and comment=\$ipv6comment] address]\
    \n    :log info \"[6rd] Created IPv6 address for interface=\$ipv6interface\
    \_with address=\$newipv6address\"\
    \n    :put \"[6rd] Created IPv6 address for interface=\$ipv6interface with\
    \_address=\$newipv6address\"\
    \n  } else={\
    \n    :if (\$ipv6poolChanged) do={\
    \n      :local oldipv6address [/ipv6 address get \$ipv6addr address]\
    \n      /ipv6 address set \$ipv6addr address=\$ipv6address from-pool=\$ipv\
    6pool\
    \n      :local newipv6address [/ipv6 address get \$ipv6addr address]\
    \n      :if (\$oldipv6address!=\$newipv6address) do={\
    \n        :log info \"[6rd] Changed IPv6 address for interface=\$ipv6inter\
    face from address=\$oldipv6address to address=\$newipv6address\"\
    \n        :put \"[6rd] Changed IPv6 address for interface=\$ipv6interface \
    from address=\$oldipv6address to address=\$newipv6address\"\
    \n      }\
    \n    }\
    \n  }\
    \n}\
    \n\
    \n# IPv6 addresses\
    \n\$changeIPv6Address ipv6interface=\$ipv6interfaceWan ipv6comment=\$ipv6a\
    ddrcomment ipv6address=(\$ipv6addressPrefix . \$ipv6suffixWan) \\\
    \n  ipv6advertise=no ipv6pool=\$ipv6pool ipv6poolChanged=\$ipv6poolChanged\
    \n\
    \n:foreach ipv6interfaceLan in=\$ipv6interfaceLanArray do={ \
    \n  \$changeIPv6Address ipv6interface=\$ipv6interfaceLan ipv6comment=\$ipv\
    6addrcomment ipv6address=\$ipv6addressLan \\\
    \n    ipv6advertise=yes ipv6pool=\$ipv6pool ipv6poolChanged=\$ipv6poolChan\
    ged\
    \n}\
    \n\
    \n# IPv6 gateway\
    \n:local ipv6route [/ipv6 route find where dst-address=\$ipv6gatewayDestin\
    ation and gateway=\$ipv6interfaceWan]\
    \n:if (\$ipv6route=\"\") do={\
    \n  :log info \"[6rd] Adding route through 6rd gateway to dst-address=\$ip\
    v6gatewayDestination\"\
    \n  :put \"[6rd] Adding route through 6rd gateway to dst-address=\$ipv6gat\
    ewayDestination\"\
    \n  /ipv6 route add dst-address=\$ipv6gatewayDestination gateway=\$ipv6int\
    erfaceWan distance=1\
    \n}"
