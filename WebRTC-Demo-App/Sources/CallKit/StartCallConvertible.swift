/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Protocol defining a type from which a call may be started.
*/

protocol StartCallConvertible {

    var startCallHandle: String? { get }
    var video: Bool? { get }

}

extension StartCallConvertible {

    var video: Bool? {
        return nil
    }

}
