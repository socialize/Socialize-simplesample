//
//  ViewController.m
//  BurgerTime
//
//  Created by Nathaniel Griswold on 1/24/12.
//  Copyright (c) 2012 Nathaniel Griswold. All rights reserved.
//

#import "ViewController.h"


@implementation ViewController
@synthesize actionBar = actionBar_;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.actionBar = [SocializeActionBar actionBarWithUrl:@"http://www.example.com/object/1234" presentModalInController:self];
    [self.view addSubview:self.actionBar.view];
}

- (void)viewDidUnload
{
    [super viewDidUnload];  
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
