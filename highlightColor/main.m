//
//  main.m
//  highlightColor
//
//  Created by Leptos on 10/25/19.
//  Copyright 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

/// @param names https://highlightjs.readthedocs.io/en/latest/css-classes-reference.html
/// @param colorDsc A space-delimited @c [0, @c 1] representation of the rgb channels, and optionally the alpha channel
static NSString *cssForHighlighNamesColorDesc(NSArray<NSString *> *names, NSString *colorDsc) {
    typedef enum : NSUInteger {
        colorChannelRed,
        colorChannelGreen,
        colorChannelBlue,
        colorChannelAlpha,
    } colorChannel;
    
    uint8_t const channelMax = 0xff;
    NSArray<NSString *> *decimalChannels = [colorDsc componentsSeparatedByString:@" "];
    NSCAssert(decimalChannels.count >= 3, @"colorDsc must contain the rgb channels");
    
    NSMutableString *colorHex = [NSMutableString stringWithCapacity:decimalChannels.count * 2];
    [decimalChannels enumerateObjectsUsingBlock:^(NSString *value, colorChannel channel, BOOL *stop) {
        if (channel <= colorChannelAlpha) {
            uint8_t channelHex = value.doubleValue * channelMax;
            if (channel == colorChannelAlpha && channelHex == channelMax) {
                /* skip alpha channel if it's full */
                return;
            }
            [colorHex insertString:[NSString stringWithFormat:@"%02x", channelHex] atIndex:channel * 2];
        }
    }];
    
    NSMutableArray<NSString *> *fullNames = [NSMutableArray arrayWithCapacity:names.count];
    [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        fullNames[idx] = [@".hljs-" stringByAppendingString:name];
    }];
    
    return [NSString stringWithFormat:@""
            "%@ {\n"
            "    color: #%@;\n"
            "}\n", [fullNames componentsJoinedByString:@",\n"], colorHex];
}

static NSString *cssForXcColorTheme(NSDictionary *coreDict) {
    switch ([coreDict[@"DVTFontAndColorVersion"] intValue]) {
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
                [ret appendString:cssForHighlighNamesColorDesc(names, coreDict[key])];
            }];
            NSDictionary<NSString *, NSString *> *syntaxColors = coreDict[@"DVTSourceTextSyntaxColors"];
            [xcodeSyntaxHighlightMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray<NSString *> *names, BOOL *stop) {
                [ret appendString:cssForHighlighNamesColorDesc(names, syntaxColors[key])];
            }];
            return ret;
        } break;
            
        default:
            return nil;
    }
}

int main(int argc, const char *argv[]) {
    const char *path = argv[1];
    if (!path) {
        /* `find $(xcode-select -p)/.. ~/Library/Developer/Xcode/UserData -name "*.xccolortheme" -type f` */
        fprintf(stderr, "Path to xccolortheme required\n");
        return 1;
    }
    
    NSString *css = cssForXcColorTheme([NSDictionary dictionaryWithContentsOfFile:@(path)]);
    puts(css.UTF8String);
    
    return 0;
}
