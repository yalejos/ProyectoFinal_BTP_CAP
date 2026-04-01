namespace com.ya;

using {
    cuid,
    managed,
    sap.common.Countries,
    sap.common.Currencies,
    sap.common.CodeList
} from '@sap/cds/common';


entity SalesHeader : cuid, managed {
    orderID      : String(36);
    email        : String(30);
    firstName    : String(30);
    lastName     : String(30);
    country      : Association to Countries;
    createOn     : Date;
    deliveryDate : DateTime;
    orderStatus  : Association to Status;
    image        : LargeBinary @Core.MediaType: imageType @UI.IsImage ;
    imageType    : String      @Core.IsMediaType;
    toSalesItems : Composition of many SalesItems
                       on toSalesItems.header = $self;
    @readonly
    totalAmount  : Decimal(15, 2);
    currency     : Association to Currencies;
    virtual isLockedInDetail : Boolean;
    
};

entity SalesItems : cuid, managed {
    itemID           : String(36);
    header           : Association to SalesHeader;
    name             : String(40);
    description      : String(36);
    releaseDate      : Date;
    virtual hasReleaseDate : Boolean;
    discontinuedDate : Date;
    price            : Decimal(12, 2);
    currency         : Association to Currencies;
    height           : Decimal(15, 3);
    width            : Decimal(13, 3);
    depth            : Decimal(12, 2);
    quantity         : Decimal(16, 2);
    unitOfMeasure    : String default 'EA';
    virtual isLockedInDetail : Boolean;

};



entity Status : CodeList {
    key code        : String enum {
            O = 'Open';
            C = 'Confirmed';
            S = 'Shipped';
            X = 'Cancelled';
        }
        criticality : Int16;
}
