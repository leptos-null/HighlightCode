//
//  main.m
//  HighlightCode
//
//  Created by Leptos on 10/25/19.
//  Copyright 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

/// @param names Each name must be one of https://highlightjs.readthedocs.io/en/latest/css-classes-reference.html
/// @param colorDsc A space-delimited @c [0,1] representation of the rgb channels, and optionally the alpha channel
static NSString *HCStyleForHighlightNamesDesc(NSArray<NSString *> *names, NSString *colorDsc) {
    typedef enum : NSUInteger {
        HCColorChannelRed,
        HCColorChannelGreen,
        HCColorChannelBlue,
        HCColorChannelAlpha,
    } HCColorChannel;
    
    uint8_t const channelMax = 0xff;
    NSArray<NSString *> *decimalChannels = [colorDsc componentsSeparatedByString:@" "];
    NSCAssert(decimalChannels.count >= 3, @"colorDsc must contain the rgb channels");
    
    NSMutableArray<NSString *> *colorHex = [NSMutableArray arrayWithCapacity:decimalChannels.count];
    [decimalChannels enumerateObjectsUsingBlock:^(NSString *value, HCColorChannel channel, BOOL *stop) {
        uint8_t channelHex = value.doubleValue * channelMax;
        
        switch (channel) {
            case HCColorChannelAlpha:
                if (channelHex == channelMax) {
                    break;
                }
            case HCColorChannelRed:
            case HCColorChannelGreen:
            case HCColorChannelBlue:
                colorHex[channel] = [NSString stringWithFormat:@"%02x", channelHex];
                break;
            default:
                break;
        }
    }];
    
    NSMutableArray<NSString *> *fullNames = [NSMutableArray arrayWithCapacity:names.count];
    [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        fullNames[idx] = [@".hljs-" stringByAppendingString:name];
    }];
    
    return [NSString stringWithFormat:@""
            "%@ {\n"
            "    color: #%@;\n"
            "}\n", [fullNames componentsJoinedByString:@",\n"], [colorHex componentsJoinedByString:@""]];
}

static NSString *HCCSSForXCColorTheme(NSDictionary *coreDict) {
    NSInteger const version = [coreDict[@"DVTFontAndColorVersion"] integerValue];
    switch (version) {
        case 1: {
            NSDictionary<NSString *, NSArray<NSString *> *> *const xcodeCoreHighlightMap = @{
                @"DVTMarkupTextInlineCodeColor" : @[ @"code", @"formula" ],
                @"DVTMarkupTextLinkColor" : @[ @"link" ],
                @"DVTMarkupTextEmphasisColor" : @[ @"emphasis" ],
                @"DVTMarkupTextStrongColor" : @[ @"strong" ],
            };
            
            NSDictionary<NSString *, NSArray<NSString *> *> *const xcodeSyntaxHighlightMap = @{
                @"xcode.syntax.keyword" : @[ @"keyword", @"literal" ],
                @"xcode.syntax.identifier.type.system" : @[ @"built_in" ],
                @"xcode.syntax.declaration.type" : @[ @"type" ],
                @"xcode.syntax.number" : @[ @"number" ],
                @"xcode.syntax.string" : @[ @"regexp", @"string", @"meta-string" ],
                @"xcode.syntax.identifier.constant" : @[ @"symbol", @"name", @"attribute" ],
                @"xcode.syntax.identifier.class.system" : @[ @"class" ],
                @"xcode.syntax.identifier.function" : @[ @"function" ],
                @"xcode.syntax.identifier.class" : @[ @"title", @"selector-class" ],
                @"xcode.syntax.comment" : @[ @"comment" ],
                @"xcode.syntax.comment.doc.keyword" : @[ @"doctag" ],
                @"xcode.syntax.preprocessor" : @[ @"meta" ],
                @"xcode.syntax.identifier.macro.system" : @[ @"meta-keyword" ],
                @"xcode.syntax.attribute" : @[ @"attr", @"tag" ],
                @"xcode.syntax.identifier.variable" : @[ @"variable" ],
                @"xcode.syntax.plain" : @[ @"subst", @"params" ],
                @"xcode.syntax.markup.code" : @[ @"section" ],
            };
            
            NSMutableString *ret = [NSMutableString string];
            [xcodeCoreHighlightMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray<NSString *> *names, BOOL *stop) {
                [ret appendString:HCStyleForHighlightNamesDesc(names, coreDict[key])];
            }];
            NSDictionary<NSString *, NSString *> *syntaxColors = coreDict[@"DVTSourceTextSyntaxColors"];
            [xcodeSyntaxHighlightMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray<NSString *> *names, BOOL *stop) {
                [ret appendString:HCStyleForHighlightNamesDesc(names, syntaxColors[key])];
            }];
            return ret;
        } break;
            
        default:
            return nil;
    }
}

int main(int argc, const char *argv[]) {
    const char *path = argv[1];
    if (path == NULL || strcmp(path, "--help") == 0) {
        /* `find $(xcode-select -p)/.. ~/Library/Developer/Xcode/UserData -name "*.xccolortheme" -type f` */
        printf("Usage: %s <xccolortheme>\n", argv[0]);
        return 1;
    }
    
    NSString *css = HCCSSForXCColorTheme([NSDictionary dictionaryWithContentsOfFile:@(path)]);
    puts(css.UTF8String);
    
    return 0;
}
