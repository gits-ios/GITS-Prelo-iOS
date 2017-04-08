# ios_prelo
prelo ios repo

### Swift Note
**********************************************
- var vs let
- no ;
- println(“variable = \(variable)”)
- var a : String[] = [“b”, “c”, “d”]
- var e = [“f” : “g”, “h” : “i”]

**********************************************
- class

class Recipe {
	var name : String?
	var duration : Int = 10
	var ingredients : String[]?

	func print(name:String) -> Int {
		println(“hello \(name)”)
		
		return 10
	}
}

var recipeItem = Recipe()
recipeItem.name = “Mushroom”
var returnItem = recipeItem.print(“Algo”)

**********************************************
- ‘!’ dan ‘?’
- kalo variabel pake ‘?’ artinya optional, jadi isinya mungkin nil
- kalo mau ngakses variabel optional, pake ‘?’ juga, untuk menanyakan apakah ada isi atau nggak, istilahnya ‘unwrap’
- kalo yakin variabel optional ada isinya, akses pake ‘!’, tapi kalo ternyata isinya nil, bakal crash.. istilahnya ‘forced unwrap’

**********************************************
- ‘_’ means don’t care

**********************************************
- external parameter

func join(string s1: String, toString s2: String, withJoiner joiner: String) -> String {
	return s1 + joiner + s2
}

‘s1’, ’s2’, dan ‘s3’ adl local parameter, ‘toString’ dan ‘withJoiner’ adl external parameter

join (“hello”, toString: “world!”, withJoiner: “, “)

atau pake ‘#’, contoh:
func join(s1: String, #withString: String)

‘withString’ jadi local sekaligus external parameter

**********************************************
- NSNotificationCenter vs delegate
NSNotificationCenter untuk pesan broadcast, delegate hanya untuk kelas yang menjadi delegate saja (single listener)

- Delegate:
- di delegator class bikin protocol dan fungsi2nya, contoh:
protocol PreloNotifListenerDelegate {
    func showNotifCount(count : Int)
}

- di delegate class set sebagai delegate, contoh:
class BaseViewController: UIViewController, PreloNotifListenerDelegate {
}

- di delegate class implement fungsi protocol, di contoh atas berarti implement showNotifCount di BaseViewController

- di delegator bikin var yang tipenya adl nama protocol, contoh:
var delegate : PreloNotifListenerDelegate?

- di delegate class set delegate dari instansiasi delegator class as self, contoh:
let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
let notifListener = delegate.preloNotifListener
notifListener.delegate = self

- di delegator manggil fungsi protocol yang sudah diimplement oleh delegate
delegate?.showNotifCount(newNotifCount)

- supaya delegator bisa ngirim suatu nilai atau data ke delegate melalui parameter

**********************************************
Cara bikin UIViewController yang dipasang di XIB (tanpa storyboard):

- New File.. > iOS > Source > Swift File, untuk bikin class
- Di dalam file baru buat kelas, contoh:
class UserProfileViewController : BaseViewController {

}
- New File.. > iOS > User Interface > Empty, untuk bikin XIB
- Pasang View Controller dari object library
- Klik ‘View Controller’ di hirarki, buka identity inspector, di Custom Class > Class isi dengan nama kelas yang baru dibikin
- Di hirarki xib pilih view controller, attributes inspector > simulated metrics > size: freeform, top bar: opaque navigation bar, terus di attributes inspector > view controller > uncheck extend edges under top bars
- Kasih scrollview dalam view utama, kasih uiview dalam scrollview (amannya pake scrollview klo2 konten ga muat, terutama antisipasi kemunculan keyboard)
- Isi content view
- Kasih constraint (jangan lupa uncheck ‘constraint to margins’!): 
	scrollview: 
		leading, trailing to superview
		top to top layout guide
		bottom to bottom layout guide
	content view/uiview dalam scrollview:
		pin height
		leading, trailing, top, bottom to superview
		equal width to uiview (scrollview’s superview)

***********************************************
Penanganan ngilangin keyboard ketika tap sembarang

- Pasang tap gesture recognizer di uiview utama
- Bikin fungsi IBAction buat ngedisable textfield (resignFirstResponder()), contoh:
	@IBAction func disableTextFields(sender : AnyObject)
    {
        fieldKodeVerifikasi?.resignFirstResponder()
    }
- Sambungin ke Connections inspector > Sent Actions > selector nya tap gesture recognizer
- Tambahin fungsi ini biar dia cuma ngedeteksi tap selain textfield dan button:
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKindOfClass(UIButton.classForCoder()) || touch.view!.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }

***********************************************
Penanganan tinggi scrollview tiap kemunculan keyboard

- Bikin IBOutlet untuk scrollview
- Masukin ke viewDidAppear dan viewWillDisappear:

	override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Mixpanel.sharedInstance().track("Phone Verification")
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }

***********************************
TEMPLATE

class PhoneReverificationViewController : BaseViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblNoHP: UILabel!
    @IBOutlet weak var fieldNoHP: UITextField!
    @IBOutlet weak var btnVerifikasi: UIButton!
    @IBOutlet weak var fieldKodeVerifikasi: UITextField!
    @IBOutlet weak var btnGantiNomor: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavBarButtons()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Mixpanel.sharedInstance().track("Phone Reverification")
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func setNavBarButtons() {
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " Edit Profil", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Tombol apply
        let applyButton = UIBarButtonItem(title: "", style:UIBarButtonItemStyle.Done, target:self, action: "simpanDataPressed:")
        applyButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = applyButton
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        fieldNoHP?.resignFirstResponder()
        fieldKodeVerifikasi?.resignFirstResponder()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
}

***********************************
Facebook login
Tutorial: http://www.brianjcoleman.com/tutorial-how-to-use-login-in-facebook-sdk-4-0-for-swift/

- Paste to Info.plist
 <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>fb860723977338277</string>
            </array>
        </dict>
    </array>
    <key>FacebookAppID</key>
    <string>860723977338277</string>
    <key>FacebookDisplayName</key>
    <string>Prelo</string>

- Kalo error mach-o linker error, karna duplicate symbols for architecture x86-64, coba pake FacebookSDK v20150813 instead of 20150910

***********************************
Path login

1. Handshake
Request:
https://partner.path.com/oauth2/authenticate?response_type=code&client_id=b0b1aca06485dadc5f9c04e799914107277a4a42

Response - Accept:
https://prelo.id/path/callback?code=43260847b16742456a67d331f7ce7db016027341
Response - Cancel:
https://partner.path.com/oauth2/decline?client_id=36dcabd7b210958cf9597045d83c9088d0624e90

(unfinished)

**************************************************
Mengubah tinggi UIView berdasarkan panjang label di dalamnya
- Contoh: di MyProductDetailVC groupPengiriman

**************************************************
UITableViewCell repeating after scroll
- Solusi: override func prepareForReuse()

**************************************************
Implement Google Analytics
- Download framework dari https://developers.google.com/analytics/devguides/collection/ios/v3/sdk-download
- Kalo make Xcode 6 ke bawah, download versi 3.13
- Extract, import ke project file2 ini:
	- GAI.h
	- GAIDictionaryBuilder.h
	- GAIEcommerceFields.h
	- GAIEcommerceProduct.h
	- GAIEcommerceProductAction.h
	- GAIEcommercePromotion.h
	- GAIFields.h
	- GAILogger.h
	- GAITrackedViewController.h
	- GAITracker.h
	- libGoogleAnalyticsServices.a

- Di Project > Build Phases > Link Binary With Libraries, tambahin:
	- CoreData.framework
	- SystemConfiguration.framework
	- libz.dylib
	- libsqlite3.dylib
	- libGoogleAnalyticsServices.a

- Di bridging-header.h, import:
	#import "GAI.h"
	#import "GAIDictionaryBuilder.h"
	#import "GAIFields.h"
	#import "GAILogger.h"
	#import "GAITrackedViewController.h"

- Configure GAI di AppDelegate.swift, fungsi didFinishLaunchingWithOptions:
	// Configure GAI options.
    var gai = GAI.sharedInstance()
    gai.trackerWithTrackingId("UA-68727101-3") // Isi dengan ID dari analytics.google.com
    gai.trackUncaughtExceptions = true  // report uncaught exceptions
    gai.logger.logLevel = GAILogLevel.Verbose  // remove before app release

- Contoh track page:
	var tracker = GAI.sharedInstance().defaultTracker
	tracker.set(kGAIScreenName, value: “Home”)
	var builder = GAIDictionaryBuilder.createScreenView()
	tracker.send(builder.build() as [NSObject : AnyObject])

- Further read: https://developers.google.com/analytics/devguides/collection/ios/v3/

**************************************************
Nambahin angka build otomatis setiap ngebuild: http://stackoverflow.com/questions/6851660/version-vs-build-in-xcode

**************************************************
Deeplinking
tutorial: http://blog.originate.com/blog/2014/04/22/deeplinking-in-ios/

Deeplinking from Facebook
https://developers.facebook.com/docs/app-ads/deep-linking
testing
https://developers.facebook.com/tools/app-ads-helper/?id=860723977338277

**************************************************
Update swiftyjson value

var tableData:JSON! /* won't update */
var tableData:JSON = JSON([:]) /* will update */ 

**************************************************
Create new core data version

- Buka file xcdatamodel yg mau dibikin versi baru
- Pilih Editor > Add Model Version
- Pilih name, based on, Finish
- Buka file xcdatamodel, di kanan ada pilihan current version, pilih yg baru dibikin
- Edit deh yg baru, udah aja

**************************************************
**************************************************
**************************************************
**************************************************
**************************************************
