//
//  RMSuggestionPanel.m
//
//  Created by Raffael Hannemann on 27.01.13.
//  Copyright (c) 2013 raffael.me. All rights reserved.
//

#import "RMSuggestionPanel.h"

#define kSearchFieldBoxHeight 31
#define kSearchFieldMarginBottom 5
#define kSearchFieldMarginSide 4 // '8' would match with window close control button
#define kSearchFieldHeight 23
#define kDefaultRowHeight 37

#define kSeparatorAlpha 0.4

#define kImageMarginLeft 4
#define kImageMarginBottom 5
#define kImageWidth 27
#define kImageHeight 27
#define kImageRadius 3
#define kTitleMarginLeft 6
#define kTitleMarginBottom 17
#define kInformationMarginLeft 6
#define kInformationMarginBottom 4
#define kTitleFontHeight 12
#define kInformationFontHeight 10

#define kDefaultConfirmWithDoubleclick YES
#define kDefaultSelectionBoxRadius 0
#define kDefaultShowSearchField YES

#define kDefaultPlaceholderString @"Search"

#pragma mark -
#pragma mark RMSuggestionTextfield Implementation

@implementation RMSuggestionListViewItem
@end

@implementation RMSuggestionPanel

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
		self.rowHeight = kDefaultRowHeight;

		_searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(0, frameRect.size.height-kSearchFieldBoxHeight+3, frameRect.size.width, kSearchFieldHeight)];
        _scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width, frameRect.size.height-kSearchFieldBoxHeight)];
		_listView = [[RMSuggestionListView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width, 0)];
		self.listView.parent = self;
		[self rebuildListView];
		[self.scrollView setDocumentView:self.listView];
		[self.scrollView setBorderType:NSNoBorder];
		[self.scrollView setAutohidesScrollers:YES];
		[self.scrollView setHasHorizontalScroller:NO];
		[self.scrollView setHasVerticalScroller:YES];
		[self.scrollView setDrawsBackground:NO];

		[self addSubview:self.searchField];
		[self addSubview:self.scrollView];

		[self.searchField setDelegate:self];
		[self setPlaceholderString:kDefaultPlaceholderString];

		self.drawBackground = YES;
		self.reactOnKeyWindowChange = YES;
		self.shrinkAutomatically = YES;
		self.sensedResponder = self.window;
		self.selectionBoxRadius = kDefaultSelectionBoxRadius;
		self.confirmWithDoubleclick = YES;
		self.selectionBoxRadius = 4;

		self.searchFieldMarginLeft = kSearchFieldMarginSide;
		self.searchFieldMarginRight = kSearchFieldMarginSide;
		self.searchFieldMarginBottom = kSearchFieldMarginBottom;
		self.showSearchField = kDefaultShowSearchField;
		
		self.defaultScrollViewHeight = self.scrollView.frame.size.height;
		manualSensedResponder = NO;

		_currentFilter = @"";

		[self scrollToTop];
    }
	
    return self;
}

- (void) setPlaceholderString:(NSString *)placeholderString {
	[self.searchField.cell setPlaceholderString:placeholderString];
}

- (void) controlTextDidChange:(NSNotification *)obj {
	[self setCurrentFilter: self.searchField.stringValue];
}

- (void) setSensedResponder:(NSResponder *)sensedResponder {
	_sensedResponder = sensedResponder;
	manualSensedResponder = YES;
}

// Panel Draw Rect
- (void) drawRect:(NSRect)dirtyRect {

	if (!manualSensedResponder)
		self.sensedResponder = self.window;
	
	[super drawRect:dirtyRect];
		
	NSColor* whiteBackground = [NSColor colorWithCalibratedWhite:0.907 alpha:(self.drawBackground)?1.0:0.0];
	if (self.drawBackground)
		[whiteBackground set];
	
	if (self.drawBackground)
		NSRectFill(NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height));

	

	self.searchField.frame = NSMakeRect(self.searchFieldMarginLeft,
										self.frame.size.height-kSearchFieldBoxHeight+kSearchFieldMarginBottom,
										self.frame.size.width-self.searchFieldMarginLeft -self.searchFieldMarginRight,
										kSearchFieldHeight);
	if (!self.showSearchField)
		[self.searchField setHidden:YES];
	
	self.scrollView.frame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height-kSearchFieldBoxHeight);

	int shouldBeAtLeast = ((int)self.filteredListItems.count)*self.rowHeight;
	int scrollHeight = self.frame.size.height-kSearchFieldBoxHeight;
	int biggerOne = (shouldBeAtLeast < scrollHeight) ? scrollHeight : shouldBeAtLeast;
	self.listView.frame = NSMakeRect(self.listView.frame.origin.x, self.listView.frame.origin.y, self.frame.size.width, biggerOne);
}

- (void) rebuildListView {
	int rows = 0;
	if (self.datasource) rows = (int)self.filteredListItems.count;
	int height = rows * self.rowHeight;
	NSRect rect = self.listView.frame;
	rect.size.height = height;
	[self.listView setFrame:rect];

	[self setNeedsDisplay:YES];

	// re-calculate required height of UI element, inform delegate if smaller than desired default height
	if (self.shrinkAutomatically) {

		int scrollViewShouldHeight = height;

		// limit the height using the default maximum height
		if (scrollViewShouldHeight > self.defaultScrollViewHeight)
			scrollViewShouldHeight = self.defaultScrollViewHeight;
		
		if (self.scrollView.frame.size.height != scrollViewShouldHeight) {
			int uiTotalHeight = scrollViewShouldHeight;

			if (self.showSearchField) {
				uiTotalHeight += kSearchFieldBoxHeight;
			}

			NSRect rect = self.scrollView.frame;
			rect.size.height = scrollViewShouldHeight;
			self.scrollView.frame = rect;

			rect = self.frame;
			rect.size.height = uiTotalHeight;

			[self setFrame: rect];
			[self.delegate suggestionPanel:self didChangeHeight:uiTotalHeight];
		}

	}
}

- (void) reloadData {

	[self.listView resetMouseClick];

	// to maintain the current user selection, store the current selected item's identifier before reloading
	NSString *currentlyHighlightedIdentifier = (self.currentlyHighlightedItem) ? self.currentlyHighlightedItem.identifier : nil;

	int rows = 0;

	//float verticalScrollingValue = [[self.scrollView verticalScroller] floatValue];
	
	NSPoint pointToScrollTo = NSMakePoint(0, 30);
	

//	NSPoint scrollPoint = [self.scrollView documentVisibleRect].origin;

	int newHighlightedIndex = -1;
	if (self.datasource) rows = [self.datasource numberOfItemsOfSuggestionPanel:self];

	NSMutableArray *listItems = [NSMutableArray array];
	for(int i=0;i<rows;i++) {
		RMSuggestionListViewItem *item = [[RMSuggestionListViewItem alloc] init];
		if ([self.datasource respondsToSelector:@selector(representedObjectOfItemIndex:ofSuggestionPanel:)])
			item.representedObject = [self.datasource representedObjectOfItemIndex:i ofSuggestionPanel:self];
		item.identifier = [self.datasource identifierOfItemIndex:i ofSuggestionPanel:self];
		item.title = [self.datasource titleOfItemIndex:i ofSuggestionPanel:self];
		item.information = [self.datasource informationTextOfItemIndex:i ofSuggestionPanel:self];
		item.image = [self.datasource imageOfItemIndex:i ofSuggestionPanel:self];
		item.isHighlighted = NO;
		item.isHidden = NO;
		item.index = i;
		[listItems addObject:item];
		if (currentlyHighlightedIdentifier && [item.identifier isEqualToString:currentlyHighlightedIdentifier]) {
			// we've found the item, that was being selected before, remember its index
			newHighlightedIndex = i;///
		}
	}

	//[[self.scrollView contentView] scrollToPoint: pointToScrollTo];
    //[self.scrollView reflectScrolledClipView: [self.scrollView contentView]];

	/*
	 [self.scrollView.contentView scrollToPoint: clipOrigin];
	 */

//	[[self.scrollView documentView] scrollPoint:scrollPoint];


	// set the index to the found index, or -1 if item is not present anymore
	self.highlightedRowIndex = newHighlightedIndex;
	[self highlightChanged];
	[self setListItems: listItems];

	// re-apply the currenxtly set filter to the reloaded data
	[self setCurrentFilter: self.searchField.stringValue];

	
	[self.listView setNeedsDisplay:YES];
}

- (void) reset {
	[self setCurrentFilter: @""];
	[self reloadData];
}

- (void) scrollToTop {
	NSPoint pt = NSMakePoint(0.0, [[self.scrollView documentView] bounds].size.height);
	[[self.scrollView documentView] scrollPoint:pt];
}

- (RMSuggestionListViewItem *) itemForIdentifier:(NSString *)identifier {
	for(RMSuggestionListViewItem *item in self.listItems) {
		if ([item.identifier isEqualToString:identifier])
			return item;
	}
	return nil;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {

	if( commandSelector == @selector(moveUp:) ){
        [self.listView selectPreceedingItem];
        return YES;
    }
	
    if( commandSelector == @selector(moveDown:) ){
		[self.listView selectNextItem];
		[self highlightChanged];
        return YES;
    }

	if( commandSelector == @selector(insertNewline:) ){
		RMSuggestionListViewItem *highlightedItem = self.currentlyHighlightedItem;
        if (highlightedItem) {
			[self confirmSelection: highlightedItem];
		}
        return YES;
    }
    return NO;    // Default handling of the command
}

- (void) setCurrentFilter:(NSString *)currentFilter {
	_currentFilter = [currentFilter stringByReplacingOccurrencesOfString:@" " withString:@""];
	[self.listView filterDidChange];
	[self rebuildListView];
}

- (void) highlightChanged {
	// if highlight is out of clipped scrolled view, move scrolling view's document view to show highligh again
	if (self.highlightedRowIndex!=-1) {
		[self.scrollView.documentView scrollRectToVisible:NSMakeRect(0, self.highlightedRowIndex*self.rowHeight, self.frame.size.width, self.rowHeight)];
	}
}

- (void) confirmSelection: (RMSuggestionListViewItem *) selectedItem {
	[self.delegate suggestionPanel:self userDidConfirmIdentifier:selectedItem.identifier];
}

@end

#pragma mark -
#pragma mark RMSuggestionListView Implementation

@implementation RMSuggestionListView

- (id)init
{
    self = [super init];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void) setParent:(RMSuggestionPanel *) newParent {
	parent = newParent;
}

-(id) initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
    if (self) {
        [self setUp];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void) setUp {
	parent.highlightedRowIndex = -1;
	[self resetMouseClick];
}

- (void) resetMouseClick {
	_mouseClick = NSMakePoint(-1, -1);
}

- (void) filterDidChange {
	[self resetMouseClick];

	// First rebuild the set of filtered items.
	[self rebuildFilteredListItems];

	// If only one single item is currently in the filtered set, select it as the current item.
	if (parent.filteredListItems.count==1) {

		// Set this one single item as the currently selected, don't set 'lastUserSelectedItem' which is only set if user actually has selected it. Set a flag to remember that this selection is synthetical
		parent.highlightedRowIndex = ((RMSuggestionListViewItem *)[parent.filteredListItems lastObject]).index;
		parent.currentlyHighlightedItem = [parent.filteredListItems lastObject];
		hasSyntheticallyDeterminedSelectedItem = YES;
		[self setNeedsDisplay:YES];
		
	} else if (parent.filteredListItems.count>1) {

		// If the filter jumps back to reveal more than once item, and the current selection is synthetical, switch back to the last user-interventioned selection
		if (hasSyntheticallyDeterminedSelectedItem && lastUserSelectedItem && !lastUserSelectedItem.isHidden) {
			parent.currentlyHighlightedItem = lastUserSelectedItem;
			parent.highlightedRowIndex = lastUserSelectedItem.index;
			hasSyntheticallyDeterminedSelectedItem = NO;
			[self setNeedsDisplay:YES];
		}
	}
}


- (void) setHighlightedRowIndex:(int)highlightedRowIndex {
	parent.highlightedRowIndex = highlightedRowIndex;
	[self setNeedsDisplay:YES];
}

- (void) rebuildFilteredListItems {
	NSString *needle = parent.currentFilter.lowercaseString;

	BOOL ignoreFilter = ([needle length]==0);

	parent.currentlyHighlightedItem = nil;
	parent.filteredListItems = [NSMutableArray array];
	for (int i=(int)parent.listItems.count-1; i>=0;i--) {
		RMSuggestionListViewItem *item = [parent.listItems objectAtIndex:i];
		NSString *searchIn = item.title.lowercaseString;
		if (ignoreFilter || [searchIn rangeOfString:needle].location!=NSNotFound) {
			[parent.filteredListItems addObject:item];
			item.isHidden = NO;
		} else {
			item.isHidden = YES;
		}
	}
}

- (void) drawRect:(NSRect)dirtyRect {
	_rowHeight = parent.rowHeight;
	for (int i=0,z=0; i<(int)parent.listItems.count; i++) {
		RMSuggestionListViewItem *item = parent.listItems[i];
		if (!item.isHidden) {
			[self drawItem:item asRow:z withOriginalIndex:i isHighlighted:(i==parent.highlightedRowIndex) andDirtyRect:dirtyRect];
			z++;
		}
	}

	/** Now, a separator between the list and the search box will be drawn based on the current scroll value of the scrollview. If the view is scrolled to the top, the line is invisible, if scrolled more than 3px, the full separator will be shown. */ 
	//// Shadow Declarations
	NSShadow* shadow = [[NSShadow alloc] init];
	float alpha = kSeparatorAlpha * (self.frame.size.height-parent.scrollView.contentView.bounds.origin.y-parent.scrollView.contentView.frame.size.height)/3.0;
	[shadow setShadowColor: [NSColor colorWithCalibratedWhite:0 alpha:alpha]];
	[shadow setShadowOffset: NSMakeSize(0.1, -2.1)];
	[shadow setShadowBlurRadius: 5];

	//// Oval Drawing
	int y = parent.scrollView.contentView.bounds.origin.y +parent.scrollView.contentView.bounds.size.height+2;

	NSBezierPath* ovalPath = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(0, y, self.frame.size.width, 12)];
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	[[NSColor whiteColor] setFill];
	[ovalPath fill];
	[NSGraphicsContext restoreGraphicsState];

	for(NSView *view in self.subviews) {
		[view setNeedsDisplay:YES];
	}
}

- (NSRect) rectForRow: (int) index {
	int offset = self.frame.size.height - parent.filteredListItems.count*_rowHeight;
	return NSMakeRect(0, index*_rowHeight+offset, self.frame.size.width, _rowHeight);
}

- (void) drawItem: (RMSuggestionListViewItem *) item asRow: (int)rowIndex withOriginalIndex:(int)originalIndex isHighlighted: (BOOL) isHighlighted andDirtyRect:(NSRect) dirtyRect {

	// get the rect for this row, for clippping and drawing
	NSRect rowRect = [self rectForRow:rowIndex];

	// if the rect is not part of the dirty rect, that needs to be refreshed, skip drawing due to performance reasons.
	if (!(rowRect.origin.y>dirtyRect.origin.y-parent.rowHeight && rowRect.origin.y<dirtyRect.origin.y+dirtyRect.size.height))
		return;

	BOOL drawLikewindowIsTopMost = !parent.reactOnKeyWindowChange || ([NSApp mainWindow]==parent.sensedResponder);

	[[NSGraphicsContext currentContext] saveGraphicsState];

	if (NSPointInRect(_mouseClick, rowRect)) {
		isHighlighted = YES;
		lastUserSelectedItem = item;
	}

	int offset = self.frame.size.height - parent.filteredListItems.count*_rowHeight;
	int y = rowIndex*_rowHeight +offset;

	NSMutableDictionary *drawStringAttributes = [[NSMutableDictionary alloc] init];
	[drawStringAttributes setValue:[NSFont fontWithName:@"HelveticaNeue-Medium" size:kTitleFontHeight] forKey:NSFontAttributeName];
	NSShadow *stringShadow = [[NSShadow alloc] init];
	NSSize shadowSize = NSMakeSize(0, -1);
	[stringShadow setShadowOffset:shadowSize];


	//// Color Declarations
	NSColor* selectedBlueTop = [NSColor colorWithCalibratedRed: 0.208 green: 0.483 blue: 0.81 alpha: 1];
	NSColor* selectedBlueBottom = [NSColor colorWithCalibratedRed: 0.295 green: 0.588 blue: 0.863 alpha: 1];
	NSColor* selectedBlueShadowBottom = [NSColor colorWithCalibratedRed: 0.138 green: 0.469 blue: 0.824 alpha: 1];
	NSColor* selectedBlueMiddle = [NSColor colorWithCalibratedRed: 0.259 green: 0.543 blue: 0.844 alpha: 1];
	NSColor* selectedBlueTopShadow = [NSColor colorWithCalibratedRed: 0.069 green: 0.316 blue: 0.64 alpha: 1];
	NSColor* whiteBackground = [NSColor colorWithCalibratedWhite:0.907 alpha:1.0];





	//// Color Declarations
	NSColor* inactiveGradientColor = [NSColor colorWithCalibratedRed: 0.606 green: 0.744 blue: 0.877 alpha: 1];
	NSColor* inactiveGradientColor2 = [NSColor colorWithCalibratedRed: 0.494 green: 0.603 blue: 0.728 alpha: 1];
	NSColor* inactiveGradientColor3 = [NSColor colorWithCalibratedRed: 0.505 green: 0.662 blue: 0.802 alpha: 1];
	NSColor* inactiveGradientColor4 = [NSColor colorWithCalibratedRed: 0.597 green: 0.725 blue: 0.863 alpha: 1];
	NSColor* inactiveGradientColor5 = [NSColor colorWithCalibratedRed: 0.606 green: 0.745 blue: 0.849 alpha: 1];

	//// Gradient Declarations
	NSGradient* inactiveGradient = [[NSGradient alloc] initWithColorsAndLocations:
									inactiveGradientColor2, 0.0,
									inactiveGradientColor4, 0.07,
									inactiveGradientColor, 0.49,
									inactiveGradientColor5, 0.93,
									inactiveGradientColor3, 1.0, nil];

	
	//// Gradient Declarations
	NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:
							selectedBlueTopShadow, 0.0,
							selectedBlueTop, 0.07,
							selectedBlueMiddle, 0.49,
							selectedBlueBottom, 0.92,
							selectedBlueShadowBottom, 1.0, nil];

	if (isHighlighted) {
		// highlighted state

		parent.highlightedRowIndex = originalIndex;
		parent.currentlyHighlightedItem = item;

		float radius = parent.selectionBoxRadius;
		NSRect blueRect = rowRect;
//		blueRect.size.height -=1;
//		blueRect.origin.y +=1;
		NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRoundedRect:blueRect xRadius:radius yRadius:radius];
		[(drawLikewindowIsTopMost)?gradient:inactiveGradient drawInBezierPath: rectanglePath angle: -90];

		[drawStringAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		[stringShadow setShadowColor:[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0.8]];
		[stringShadow setShadowBlurRadius:3];


	} else {
		// not-highlighted state
		
		if (parent.drawBackground) {
			[whiteBackground set];
			NSRect boxRect = rowRect;
			boxRect.origin.y+=1;
			boxRect.size.height-=1;
			NSRectFill(rowRect);
		}

		if (rowIndex%2==1 && parent.alternatingColor) {
			[parent.alternatingColor set];
			NSRectFillUsingOperation(rowRect, NSCompositeSourceOver);
		}
		
		[drawStringAttributes setValue:[NSColor colorWithSRGBRed:0.3 green:0.3 blue:0.3 alpha:1] forKey:NSForegroundColorAttributeName];
		[stringShadow setShadowColor:[NSColor whiteColor]];
		[stringShadow setShadowBlurRadius:0];


		// Separator drawing
		int shrinkVertical = parent.selectionBoxRadius;
		//// Separator1pxTop Drawing
		NSRect separator1pxTop = rowRect;
		separator1pxTop.size.height = 1;
		separator1pxTop.size.width -=shrinkVertical;
		separator1pxTop.origin.x +=shrinkVertical;
		separator1pxTop.origin.y += separator1pxTop.size.height-1;

		NSRect separator1pxBottom = rowRect;
		separator1pxBottom.size.height = 1;
		separator1pxBottom.size.width -=shrinkVertical;
		separator1pxBottom.origin.x +=shrinkVertical;
		separator1pxBottom.origin.y -=1;

		if (parent.highlightedRowIndex!=originalIndex-1 && rowIndex!=0) {

			[[NSColor colorWithCalibratedRed: 0.817 green: 0.817 blue: 0.817 alpha: 1] set];
			NSRectFill(separator1pxTop);

			[[NSColor whiteColor] set];
			NSRectFill(separator1pxBottom);
		}
	}

	[drawStringAttributes setValue:stringShadow forKey:NSShadowAttributeName];

	BOOL informationTextExist = (item.information && ![item.information isEqualToString:@""]);

	int textOffset = (informationTextExist) ? 0 : -5;
	[item.title drawAtPoint:NSMakePoint(kTitleMarginLeft+kImageMarginLeft+kImageWidth, y+kTitleMarginBottom+textOffset) withAttributes:drawStringAttributes];

	[drawStringAttributes setValue:[NSFont fontWithName:@"HelveticaNeue-Medium" size:kInformationFontHeight] forKey:NSFontAttributeName];

	// Information

	if (informationTextExist)
		[item.information drawAtPoint:NSMakePoint(kInformationMarginLeft+kImageMarginLeft+kImageWidth, y+kInformationMarginBottom) withAttributes:drawStringAttributes];

	// Image
	if (item.image) {
		NSRect targetRect = NSMakeRect(kImageMarginLeft, y+kImageMarginBottom, kImageWidth, kImageHeight);

		/** Really, I love PaintCode, buy it. */
		
		//// Shadow Declarations
		NSShadow* whiteBottomShadowSelected = [[NSShadow alloc] init];
		float shadowAlpha = (isHighlighted) ? 0.4 : 1.0;
		[whiteBottomShadowSelected setShadowColor: [NSColor colorWithCalibratedWhite:1.0 alpha:shadowAlpha]];
		[whiteBottomShadowSelected setShadowOffset: NSMakeSize(0.6, -2.1)];
		[whiteBottomShadowSelected setShadowBlurRadius: 0];
		NSShadow* innerShadow = [[NSShadow alloc] init];
		[innerShadow setShadowColor: [NSColor blackColor]];
		[innerShadow setShadowOffset: NSMakeSize(0.1, 0.1)];
		[innerShadow setShadowBlurRadius: 1.5];

		//// Abstracted Attributes
		NSRect whiteBottomShadowRect = NSMakeRect(targetRect.origin.x+1, targetRect.origin.y+1, targetRect.size.width-2, targetRect.size.height-2);
		CGFloat whiteBottomShadowCornerRadius = 3;
		NSRect imageRect = targetRect;
		CGFloat imageCornerRadius = 3;
		NSRect overlayRect = targetRect;
		CGFloat overlayCornerRadius = 3;

		//// whiteBottomShadow Drawing
		NSBezierPath* whiteBottomShadowPath = [NSBezierPath bezierPathWithRoundedRect: whiteBottomShadowRect xRadius: whiteBottomShadowCornerRadius yRadius: whiteBottomShadowCornerRadius];
		[NSGraphicsContext saveGraphicsState];
		[whiteBottomShadowSelected set];
		[[NSColor whiteColor] setFill];
		[whiteBottomShadowPath fill];
		[NSGraphicsContext restoreGraphicsState];

		//// image Drawing
		NSBezierPath* imagePath = [NSBezierPath bezierPathWithRoundedRect: imageRect xRadius: imageCornerRadius yRadius: imageCornerRadius];
		[NSGraphicsContext saveGraphicsState];
		[whiteBottomShadowSelected set];

		NSRect rect = NSMakeRect(0, 0, item.image.size.width, item.image.size.height);

		[imagePath addClip];
		[item.image drawInRect:targetRect fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
		
		[NSGraphicsContext restoreGraphicsState];

		//// overlay Drawing
		NSBezierPath* overlayPath = [NSBezierPath bezierPathWithRoundedRect: overlayRect xRadius: overlayCornerRadius yRadius: overlayCornerRadius];
		[NSGraphicsContext saveGraphicsState];
		[whiteBottomShadowSelected set];
		[[NSColor clearColor] setFill];
		[overlayPath fill];

		////// overlay Inner Shadow
		NSRect overlayBorderRect = NSInsetRect([overlayPath bounds], -innerShadow.shadowBlurRadius, -innerShadow.shadowBlurRadius);
		overlayBorderRect = NSOffsetRect(overlayBorderRect, -innerShadow.shadowOffset.width, -innerShadow.shadowOffset.height);
		overlayBorderRect = NSInsetRect(NSUnionRect(overlayBorderRect, [overlayPath bounds]), -1, -1);

		NSBezierPath* overlayNegativePath = [NSBezierPath bezierPathWithRect: overlayBorderRect];
		[overlayNegativePath appendBezierPath: overlayPath];
		[overlayNegativePath setWindingRule: NSEvenOddWindingRule];

		[NSGraphicsContext saveGraphicsState];
		{
			NSShadow* innerShadowWithOffset = [innerShadow copy];
			CGFloat xOffset = innerShadowWithOffset.shadowOffset.width + round(overlayBorderRect.size.width);
			CGFloat yOffset = innerShadowWithOffset.shadowOffset.height;
			innerShadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
			[innerShadowWithOffset set];
			[[NSColor grayColor] setFill];
			[overlayPath addClip];
			NSAffineTransform* transform = [NSAffineTransform transform];
			[transform translateXBy: -round(overlayBorderRect.size.width) yBy: 0];
			[[transform transformBezierPath: overlayNegativePath] fill];
		}
		[NSGraphicsContext restoreGraphicsState];
		
		[NSGraphicsContext restoreGraphicsState];
	}

	// allow easy painting over
	if (parent.rowOverlayDrawingBlock) {
		parent.rowOverlayDrawingBlock(item, drawLikewindowIsTopMost, isHighlighted, rowRect, rowIndex, originalIndex);
	}
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void) mouseDragged:(NSEvent *)theEvent {
	if ([theEvent window]==self.window) {
		//_mouseClick = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		[self resetMouseClick];
	}
	[self setNeedsDisplay:YES];
}

- (void) mouseDown:(NSEvent *)theEvent {
	if (theEvent.modifierFlags & NSControlKeyMask)
		[self rightMouseDown:theEvent];
	else {
		if ([theEvent window]==self.window) {
			parent.highlightedRowIndex = -1;
			_mouseClick = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		}
		[self setNeedsDisplay:YES];
	}
}

- (void) rightMouseDown:(NSEvent *) theEvent {
	//int offset = self.frame.size.height - parent.listItems.count*_rowHeight;
	int y = [self convertPoint:[theEvent locationInWindow] fromView:nil].y;
	int rightclickedIndex = floor( (y)/_rowHeight);
	NSString *identifier = ((RMSuggestionListViewItem *)[[parent filteredListItems] objectAtIndex:[parent.filteredListItems count]-1-rightclickedIndex]).identifier;
	if ([parent.delegate respondsToSelector:@selector(suggestionPanel:userDidSecondaryClickOnItemIdentifier:withEvent:)])
		[parent.delegate suggestionPanel:parent userDidSecondaryClickOnItemIdentifier:identifier withEvent:theEvent];
}

- (void) mouseUp:(NSEvent *)theEvent {
	if ([theEvent window]==self.window) {
		_mouseClick = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	}
	[self setNeedsDisplay:YES];

	BOOL userHasChosen;
	if (parent.confirmWithDoubleclick) userHasChosen = ([theEvent clickCount]>=2);
	else userHasChosen = ([theEvent clickCount]==1);
	if (userHasChosen && parent.currentlyHighlightedItem) {
		[parent confirmSelection:parent.currentlyHighlightedItem];
	}
}

/*
 - (void) handleMouseDownWithY: (int) y {
	int offset = self.frame.size.height - parent.listItems.count*_rowHeight;
	parent.highlightedRowIndex = floor( (y-offset)/_rowHeight);


	[self setNeedsDisplay:YES];
}
 */

- (void) keyDown: (NSEvent *) event
{
    NSString *chars = [event characters];
    unichar character = [chars characterAtIndex: 0];

    if (character == 27) {
		parent.highlightedRowIndex = -1;
    }
}

- (void) selectNextItem {
	int foundIndex = parent.highlightedRowIndex;
	if (foundIndex==-1) foundIndex = (int)parent.listItems.count;
	RMSuggestionListViewItem *item;
	for (int i=foundIndex-1; i>=0; i--) {
		item = [parent.listItems objectAtIndex:i];
		if (!item.isHidden) {
			foundIndex = i;
			lastUserSelectedItem = item;
			break;
		}
	}
	[self resetMouseClick];
	parent.highlightedRowIndex = foundIndex;
	[parent highlightChanged];
	[self setNeedsDisplay:YES];
}

- (void) selectPreceedingItem {
	int foundIndex = parent.highlightedRowIndex;
	if (foundIndex==-1) foundIndex = (int)parent.listItems.count-1;

	RMSuggestionListViewItem *item;
	for (int i=foundIndex+1; i<parent.listItems.count; i++) {
		item = [parent.listItems objectAtIndex:i];
		if (!item.isHidden) {
			foundIndex = i;
			lastUserSelectedItem = item;
			break;
		}
	}
	[self resetMouseClick];
	parent.highlightedRowIndex = foundIndex;
	[parent highlightChanged];
	[self setNeedsDisplay:YES];
}
@end
