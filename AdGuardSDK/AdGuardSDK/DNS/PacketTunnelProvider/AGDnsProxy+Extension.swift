/**
       This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
       Copyright © Adguard Software Limited. All rights reserved.
 
       Adguard for iOS is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.
 
       Adguard for iOS is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.
 
       You should have received a copy of the GNU General Public License
       along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

// MARK: - AGDnsStamp + DnsProtocol

extension AGDnsStamp {
    var dnsProtocol: DnsProtocol { proto.dnsProtocol }
}

// MARK: - AGStampProtoType + DnsProtocol

extension AGStampProtoType {
    var dnsProtocol: DnsProtocol {
        switch self {
        case .AGSPT_PLAIN: return .dns
        case .AGSPT_DOH: return .doh
        case .AGSPT_TLS: return .dot
        case .AGSPT_DNSCRYPT: return .dnscrypt
        case .AGSPT_DOQ: return .doq
        @unknown default:
            assertionFailure("Unhandled AGStampProtoType type")
            return .dns
        }
    }
}

// MARK: - AGDnsUpstream + DnsProxyUpstream init

extension AGDnsUpstream {
    convenience init(from upstream: DnsProxyUpstream) {
        self.init(
            address: upstream.dnsUpstreamInfo.upstream,
            bootstrap: upstream.dnsBootstraps.map { $0.upstream },
            timeoutMs: AGDnsUpstream.defaultTimeoutMs,
            serverIp: nil,
            id: upstream.id,
            outboundInterfaceName: nil
        )
    }
}

// MARK: - AGDnsFilterParams + DnsProxyFilter init

extension AGDnsFilterParams {
    convenience init(from filter: DnsProxyFilter) {
        self.init(
            id: filter.filterId,
            data: filter.filterPath,
            inMemory: false
        )
    }
}

// MARK: - AGDns64Settings + DnsProxy64Settings init

extension AGDns64Settings {
    convenience init(from upstreams: [DnsProxyUpstream]) {
        self.init(
            upstreams: upstreams.map { AGDnsUpstream(from: $0) },
            maxTries: 2,
            waitTimeMs: AGDnsUpstream.defaultTimeoutMs
        )
    }
}

// MARK: - AGDnsUpstream + defaultTimeoutMs

public extension AGDnsUpstream {
    /// AGDnsProxy Fallback timeout
    static let defaultTimeoutMs = 2000
}

// MARK: - AGDnsProxyConfig + DnsProxyConfiguration

extension AGDnsProxyConfig {
    /// Initializer for `AGDnsProxyConfig` from `DnsProxyConfiguration`
    /// We use `DnsProxyConfiguration` to be able to test how we configure `AGDnsProxyConfig`
    convenience init(from configuration: DnsProxyConfiguration) {
        let defaultConfig = AGDnsProxyConfig.getDefault()!
        self.init(
            upstreams: configuration.upstreams.map { AGDnsUpstream(from: $0) },
            fallbacks: configuration.fallbacks.map { AGDnsUpstream(from: $0) },
            fallbackDomains: defaultConfig.fallbackDomains,
            detectSearchDomains: defaultConfig.detectSearchDomains,
            filters: configuration.filters.map { AGDnsFilterParams(from: $0) },
            blockedResponseTtlSecs: configuration.blockedResponseTtlSecs,
            dns64Settings: AGDns64Settings(from: configuration.dns64Upstreams),
            listeners: nil,
            outboundProxy: defaultConfig.outboundProxy,
            ipv6Available: configuration.ipv6Available,
            blockIpv6: configuration.blockIpv6,
            adblockRulesBlockingMode: configuration.rulesBlockingMode.agRulesBlockingMode,
            hostsRulesBlockingMode: configuration.hostsBlockingMode.agHostsRulesBlockingMode,
            customBlockingIpv4: configuration.customBlockingIpv4,
            customBlockingIpv6: configuration.customBlockingIpv6,
            dnsCacheSize: 128,
            optimisticCache: false,
            enableDNSSECOK: false,
            enableRetransmissionHandling: true,
            helperPath: nil
        )
    }
}