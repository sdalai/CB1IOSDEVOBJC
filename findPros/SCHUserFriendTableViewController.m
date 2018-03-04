//
//  SCHUserFriendTableViewController.m
//  CounterBean
//
//  Created by Sujit Dalai on 3/27/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHUserFriendTableViewController.h"
#import "SCHUserFriend.h"
#import "SCHUser.h"

@interface SCHUserFriendTableViewController ()

@property (nonatomic, strong) NSArray *FriendList;

@end

@implementation SCHUserFriendTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.FriendList = [[NSMutableArray alloc]init];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Friends";
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    PFQuery *friendsQuery = [SCHUserFriend query];
    [friendsQuery fromLocalDatastore];
    [friendsQuery includeKey:@"CBFriend"];
    [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable friends, NSError * _Nullable error) {
        
        
        if (friends.count){
            self.FriendList = friends;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.FriendList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }

    SCHUserFriend *userfriend = [self.FriendList objectAtIndex:indexPath.row];
    SCHUser *user = userfriend.CBFriend;
    // Configure the cell...
 
    NSString *name = [NSString stringWithFormat:@"%@ %@", user.firstName,user.lastName];
    cell.textLabel.text = name;
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
