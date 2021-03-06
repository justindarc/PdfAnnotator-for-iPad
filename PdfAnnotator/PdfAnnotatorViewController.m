// Copyright (C) 2011 by Raphael Cruzeiro
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PdfAnnotatorViewController.h"
#import "LoadMenuController.h"
#import "PDFDocument.h"
#import "PDFPageViewController.h"
#import "PDFPagingViewController.h"
#import "TextMarkerSelectorViewController.h"

#import <QuartzCore/QuartzCore.h>

@implementation PdfAnnotatorViewController

@synthesize pageViewController;
@synthesize textMarkerController;
@synthesize loadMenu;
@synthesize popOver;
@synthesize toolbar;
@synthesize load;
@synthesize hand;
@synthesize saveButton;
@synthesize undo;
@synthesize redo;
@synthesize eraser;
@synthesize textMarker;
@synthesize document;

@synthesize documentView;

- (void)dealloc
{
    [pageViewController release];    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.load.target = self;
    self.load.action = @selector(loadClicked:);
    
    [self.hand setImage:[UIImage imageNamed:@"hand.png"]];
    self.hand.target = self;
    self.hand.action = @selector(handClicked:);
    
    [self.textMarker setImage:[UIImage imageNamed:@"textMarker.png"]];
    self.textMarker.target = self;
    self.textMarker.action = @selector(textMarkerClicked:);
    
    self.saveButton.target = self;
    self.saveButton.action = @selector(saveClicked:);
    
    [self.undo setImage:[UIImage imageNamed:@"undo.png"]];
    self.undo.target = self;
    self.undo.action = @selector(undoClicked:);
    
    [self.redo setImage:[UIImage imageNamed:@"redo.png"]];
    self.redo.target = self;
    self.redo.action = @selector(redoClicked:);
    
    [self.eraser setImage:[UIImage imageNamed:@"eraser.png"]];
    self.eraser.target = self;
    self.eraser.action = @selector(eraserClicked:);
    
    [self.toolbar setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundTile"]];
    
    [self resetButtonStates];
}

- (void)resetButtonStates
{
    [self.hand setEnabled:NO];
    [self.textMarker setEnabled:NO];
    [self.saveButton setEnabled:NO];
    [self.undo setEnabled:NO];
    [self.redo setEnabled:NO];
    [self.eraser setEnabled:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)loadClicked:(id)sender
{
    if(!self.popOver) {
        self.loadMenu = [[[LoadMenuController alloc] initWithObserver:self] autorelease];
        self.popOver = [[[UIPopoverController alloc] initWithContentViewController:loadMenu] autorelease];
        
        [self.popOver presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

- (void)handClicked:(id)sender
{
    if(pageViewController) {
        NSLog(@"Entering hand mode");
        [pageViewController setHandMode:YES];
        
        [self.hand setEnabled:NO];
        [self.textMarker setEnabled:YES];
        [self.eraser setEnabled:YES];
    }
}

- (void)textMarkerClicked:(id)sender
{
    textMarkerController = [[TextMarkerSelectorViewController alloc] initWithObserver:self];
    self.popOver = [[[UIPopoverController alloc] initWithContentViewController:textMarkerController] autorelease];
    popOver.popoverContentSize = CGSizeMake(215, 46);
    [self.popOver presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)brushSelected:(TextMarkerBrush)brush
{
    if(pageViewController) {
        [pageViewController setBrush:brush];
        [pageViewController setPenMode:YES];
    }
    
    [self.popOver dismissPopoverAnimated:YES];
    
    [self.hand setEnabled:YES];
    [self.eraser setEnabled:YES];
    [self.textMarker setEnabled:NO];
}

- (void)saveClicked:(id)sender
{
    if([self.document save]) {
        [self.saveButton setTitle:@"Saved"];
        [self.saveButton setEnabled:NO];
    }
}

- (void)documentChoosen:(NSString *)_document
{
    //NSLog(@"%s", [[_document absoluteString] UTF8String]);
    
    [self resetButtonStates];
    
    [self.popOver dismissPopoverAnimated:YES];
    
    self.popOver = nil;
    
    if(self.document != NULL) {
        [pageViewController.view removeFromSuperview];
        [pageViewController release];
    }
    
    self.document = [[[PDFDocument alloc] initWithDocument:_document] autorelease];
    
    pageViewController = [[PDFPageViewController alloc] initWithDelegate:self];
    [pageViewController loadDocument:self.document];
    
    [self.view addSubview:[pageViewController view]];
    [self.view bringSubviewToFront:toolbar];
    
    [self.textMarker setEnabled:YES];
    [self.eraser setEnabled:YES];
}

- (void)undoClicked:(id)sender
{
    if(pageViewController) {
        [pageViewController undo];
        [self.redo setEnabled:YES];
    }
}

- (void)redoClicked:(id)sender
{
    if(pageViewController) {
        [pageViewController redo];
    }
}

- (void)eraserClicked:(id)sender
{
    [eraser setEnabled:NO];
    [hand setEnabled:YES];
    [textMarker setEnabled:YES];
    
    if(pageViewController) {
        [pageViewController setEraserMode:YES];
    }
}

- (void)switchToHandMode
{
    [self.eraser setEnabled:YES];
    [self.textMarker setEnabled:YES];
    [self.hand setEnabled:NO];
}

- (void)changed
{
    self.document.dirty = YES;
    
    if(document.dirty) {
        [self.saveButton setTitle:@"Save"];
        [self.saveButton setEnabled:YES];
    }
}

- (void)canUndo:(BOOL)value
{
    [self.undo setEnabled:value];
}

- (void)canRedo:(BOOL)value
{
    [self.redo setEnabled:value];
}

@end


@implementation UIToolbar (CustomImage)
- (void)drawRect:(CGRect)rect {
    UIImage *image = [UIImage imageNamed: @"toolbarBg.png"];
    [image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}
@end