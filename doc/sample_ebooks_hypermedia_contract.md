# @title Sample eBooks Hypermedia Contract

The following sample Hypermedia resource contract defines the state-machine API for a subset of resources in a service 
or the platform in general. That is, it does not specify a monolithic contract for an entire service, but rather 
resources, irrespective of the service the actually reside in.

Depending on the nature of the associated workflow, there may only be one resource represented, or possibly as a list 
resource and an entity resource.

## Resource: eBooks
Represents a list of eBooks.

### Entry Point

* http://example.org/ebooks

### Data Semantics

* total_count - The total number of all eBooks
* items - An embedded list of individual eBook items

### Link Relations

* list - A list of available eBooks
* search - Filter a list of eBooks using the search criteria

    Parameters: 
    
    * name - The title of an eBook
    * search_text - The text of an eBook
        
* create - Creates a new eBook
    
    Attributes:
       
    * name - The title of the eBook
    * text - The text of the eBook
    * author_url - The URL of the associated author

## Resource: eBook
Represents an eBook.

### Data Semantics

* name - The title of an eBook
* text - The text of an eBook
* status - Whether the eBook is a rough draft, draft or published
* author - An optionally embedded author resource

### Link Relations

* show - View an eBook
* edit - Edits an eBook's properties

    Attributes:
       
    * name - The title of the eBook
    * text - The text of the eBook

* copy - Copies an eBook
* release - Promotes an eBook
* delete - Deletes an eBook
* author - Links to the author of the eBook
