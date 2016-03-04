/**
    This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
    Copyright © 2015 Performix LLC. All rights reserved.
 
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

/**
* Adguard rules constructor library
*/
var AdguardRulesConstructorLib = (function (api) {

  var makeCssNthChildFilter = function (element) {

    var path = [];
    var el = element;
    while (el.parentNode) {
      var nodeName = el && el.nodeName ? el.nodeName.toUpperCase() : "";
      if (nodeName == "BODY") {
        break;
      }
      if (el.id) {
        var id = el.id.split(':').join('\\:');//case of colon in id. Need to escape
        if (el.id.indexOf('.') > -1) {
          path.unshift('[id="' + id + '"]');
        } else {
          path.unshift('#' + id);
        }
        break;
      } else {
        var c = 1;
        for (var e = el; e.previousSibling; e = e.previousSibling) {
          if (e.previousSibling.nodeType === 1) {
            c++;
          }
        }

        var cldCount = 0;
        for (var i = 0; el.parentNode && i < el.parentNode.childNodes.length; i++) {
          cldCount += el.parentNode.childNodes[i].nodeType == 1 ? 1 : 0;
        }

        var ch;
        if (cldCount == 0 || cldCount == 1) {
          ch = "";
        } else if (c == 1) {
          ch = ":first-child";
        } else if (c == cldCount) {
          ch = ":last-child";
        } else {
          ch = ":nth-child(" + c + ")";
        }

        var className = el.className;
        if (className) {
          if (className.indexOf('.') > 0) {
            className = '[class="' + className + '"]';
          } else {
            className = className.trim().replace(/\s+(?= )/g, ''); //delete more than one space between classes;
            className = '.' + className.replace(/\s/g, ".");
          }
        } else {
          className = '';
        }
        path.unshift(el.tagName + className + ch);

        el = el.parentNode;
      }
    }
    return path.join(" > ");
  };

  var createRuleText = function (element) {
    if (!element) {
      return;
    }

    var selector = makeCssNthChildFilter(element);
    return selector ? "##" + selector : "";
  };

  var createSimilarRuleText = function (element) {
    if (!element) {
      return "";
    }

    var className = element.className;
    if (!className) {
      return "";
    }

    var selector = className.trim().replace(/\s+/g, ', .');
    return selector ? "##" + '.' + selector : "";
  };

  var constructUrlBlockRuleText = function (element, urlBlockAttribute, oneDomain, domain) {
    if (!urlBlockAttribute || urlBlockAttribute == '') {
      return null;
    }

    var blockUrlRuleText = urlBlockAttribute.replace(/^http:\/\/(www\.)?/, "||");
    if (blockUrlRuleText.indexOf('.') == 0) {
      blockUrlRuleText = blockUrlRuleText.substring(1);
    }

    if (!oneDomain) {
      blockUrlRuleText = blockUrlRuleText + "$" + "domain=" + domain;
    }

    return blockUrlRuleText;
  };

  /**
  * Utility method
  *
  * @param element
  * @returns {string}
  */
  api.makeCssNthChildFilter = makeCssNthChildFilter;

  /**
  * Constructs adguard rule text from element node and specified options
  *
  * var options = {
  *  isBlockByUrl: boolean,
  *	urlBlockAttribute: url mask,
  *	isBlockSimilar : boolean,
  *	isBlockOneDomain: boolean,
  *	domain: domain string
  * }
  *
  * @param element
  * @param options
  * @returns {*}
  */
  api.constructRuleText = function (element, options) {
    if (options.isBlockByUrl) {
      var blockUrlRuleText = constructUrlBlockRuleText(element, options.urlMask, options.isBlockOneDomain, options.domain);
      if (blockUrlRuleText) {
        return blockUrlRuleText;
      }
    }

    var result;
    if (options.isBlockSimilar) {
      result = createSimilarRuleText(element);
    } else {
      result = createRuleText(element);
    }

    if (!options.isBlockOneDomain) {
      result = options.domain + result;
    }

    return result;
  };

  return api;

})(AdguardRulesConstructorLib || {});
