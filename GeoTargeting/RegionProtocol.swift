//
//  Created by Utkarsh Phirke
//  Copyright © 2018 CakeSoft. All rights reserved.
//


import CoreLocation


protocol RegionProtocol {
	var coordinate: CLLocation {get}
	var radius: CLLocationDistance {get}
	var identifier: String {get}

	func updateRegion()
}
