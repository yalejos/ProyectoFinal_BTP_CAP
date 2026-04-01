using {SalesOrder as service} from '../service';

annotate service.SalesItems with {
    itemID        @title: 'Item ID'   @Core.Computed  @Common.FieldControl: #ReadOnly;
    name          @title: 'Product';
    quantity      @title: 'Quantity'  @Measures.Unit       : 'unitOfMeasure';
    unitOfMeasure @title: 'Unit of Measure';
    price         @title: 'Price'    
                  @Measures.ISOCurrency: currency_code
                  @Criticality: {$edmJson: {$If: [
                                {$Eq: [{$Path: 'price'}, 0]},
                                     1, // Rojo si es 0
                                     3  // Verde si tiene valor
                  ]}};
    currency      @title: 'Currency'  @Common.IsCurrency;
    releaseDate   @title: 'Realease Date';
    discontinuedDate @title: 'Discontinued Date';


};

annotate service.SalesItems with @(

    UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: itemID
    },
    {
        $Type: 'UI.DataField',
        Value: name
    },
    {
        $Type: 'UI.DataField',
        Value: quantity
    },
    {
        $Type: 'UI.DataField',
        Value: price
    },
    {
        $Type: 'UI.DataField',
        Value: releaseDate
    },
    {
        $Type: 'UI.DataField',
        Value: discontinuedDate
    },
    // Actions en la tabla de ítems
    {
        $Type : 'UI.DataFieldForAction',
        Action: 'service.releaseProduct',
        Label : 'Release Product',
        //Inline: true
    },
    {
        $Type : 'UI.DataFieldForAction',
        Action: 'service.discontinueProduct',
        Label : 'Discontinue',
       // Inline: true
    }
]);

annotate service.SalesItems with @(
    // Configuración de la cabecera del Object Page del Item
    Common.Label : 'Sales Item',
    UI.HeaderInfo                : {
        TypeName      : 'Item Detail',
        TypeNamePlural: 'Item Details',
        Title         : {Value: name},
    //Description   : {Value: description}
    },

    // Definición de las secciones (Tabs/Facets)
    UI.Facets                    : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Product Information',
            Target: '@UI.FieldGroup#ProductDetails'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Dimensions',
            Target: '@UI.FieldGroup#Dimensions'
        }
    ],


    // Grupo de campos: Información General del Producto
    UI.FieldGroup #ProductDetails: {Data: [
        {
            $Type: 'UI.DataField',
            Value: name
        },
        {
            $Type: 'UI.DataField',
            Value: description
        },
        {
            $Type: 'UI.DataField',
            Value: quantity
        },
        {
            $Type: 'UI.DataField',
            Value: unitOfMeasure
        },
        {
            $Type: 'UI.DataField',
            Value: price
        },

        {
            $Type: 'UI.DataField',
            Value: releaseDate
        },
        {
            $Type: 'UI.DataField',
            Value: discontinuedDate
        }
    ]},

    // Grupo de campos: Dimensiones Físicas
    UI.FieldGroup #Dimensions    : {Data: [
        {
            $Type: 'UI.DataField',
            Value: height,
            Label: 'Height'
        },
        {
            $Type: 'UI.DataField',
            Value: width,
            Label: 'Width'
        },
        {
            $Type: 'UI.DataField',
            Value: depth,
            Label: 'Depth'
        }
    ]}

);




annotate SalesOrder.SalesItems with @(
    Common.SideEffects                 : {
        $Type           : 'Common.SideEffectsType',
        SourceEntities  : [$self],
        TargetProperties: [itemID],
        TargetEntities : [ $self ]
    },
    Common.SideEffects #ProductReleased: {
        $Type           : 'Common.SideEffectsType',
        SourceProperties  : [ releaseDate, discontinuedDate],
        TargetProperties: [
            releaseDate,
            discontinuedDate
        ],
        TargetEntities : [ $self ]
    },
    Common.SideEffects #AmountChanged : {
        SourceProperties : [ price, quantity, discontinuedDate ],
        TargetEntities : [ header ]
    }
   
);

annotate service.SalesItems with {
    hasReleaseDate  @cds.on.insert: false @cds.on.update: false;
};

annotate service.SalesItems with actions {
   @Core.OperationAvailable: { $edmJson: { $And: [
        { $Not: { $Path: 'releaseDate' } },
        { $Eq: [{ $Path: 'IsActiveEntity' }, false] }
    ]}}
    releaseProduct;

    @Core.OperationAvailable: { $edmJson: { $And: [
         { $Path: 'hasReleaseDate' },
        { $Eq: [{ $Path: 'IsActiveEntity' }, false] }
    ]}}
    discontinueProduct;
};


