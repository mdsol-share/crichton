# @title Sample eBooks State-machine Analysis

# Overview
To determine the appropriate state machine that is associated with a resource or set of closely related resources, 
one must understand concepts and principles behind the following:

* [Finite State Machines](http://en.wikipedia.org/wiki/Finite-state_machine)
* [State Design Pattern](http://en.wikipedia.org/wiki/State_pattern)

Further, one must understand the constraints on available state transitions based on:

* Business Rules driven by the data properties
* Permissions driven by context; that is, Roles, Traits, and so on.

The following discussion assumes that you have performed a semantic analysis associated with resource data and link relations. The discussion outlines steps to determine the appropriate state machine that represents the resource workflow and the resource's relationships to other resources.

## Hypermedia State Transitions
Available state transitions are present in Hypermedia responses (depending on media-type) as links with defined link 
relations. These transitions, which are discovered at runtime, will transition either resource state or application state.

### Resource State Transitions
Resource state transitions transform the state of a resource. Transformation can include such actions as updating properties, locking them, and so on. Resource state transitions are semantically defined as verbs.

### Application State Transitions
Application state transitions transform the state of an application. Transformation here means the transitions state from one resource to another. Application state transitions are semantically defined as nouns.

## Finding the states
Depending on the nature of the workflow associated with a particular resource or related set of resources, the state(s) 
of the resource can be obvious. On the other hand, they can take a while to expose. Technically, you can argue that for any resource where one can modify the underlying data there are an infinite number of resource states. While logically true, this is not useful in helping to determine the states and related transitions for a Hypermedia API. 

> States are associated with distinct sets of possible state transitions or dissimilar permission rules for the same set
of transitions in a resource.

The following description outlines a number of ideas and constraints to determine the state-machine API of resources. For the sake  of illustration, we work on the related state-machines of the 'eBooks' and 'eBook' resources that were analyzed and summarized in the [Sample eBooks Hypermedia Contract][].

The 'eBooks' resource has the following link relations:

* list 
* search
* create

The 'eBook' resource has the following set of link relations:

* read
* edit
* copy
* publish
* delete
* author

### Isolate unique sets of link relations
Business rules associated with the underlying work that a resource does dictate which link relations are available based on some aspect of the data. This may be some combination of data elements to define the state or effectively some property like a "status" on underlying data. To determine states, one attempts to find groups of resources that are context independent. That is, for example, they exist in the state for some user or they don't exist in a state, regardless of use.

#### eBooks Example
In our sample analysis, we first found two states for eBooks that we called Draft and Published. These states have the following link relations:

* Collection: list (self), search, create
* Navigation: list, search (self), create

You could say that a single state is sufficient for a resource that lists other resources. However, as a 
practice once you apply a search or filter transition, the data of the resource is in a different state than 
the base URI of the resource as the full collection, even when it is paginated.

#### eBook Example
In our sample analysis, we initially also found two states for eBook that we called Draft and Published. These states have the following link relations:

* Draft: read (self), edit, copy, publish, delete, author
* Published: read (self), author

NOTE: The name of the state ideally encapsulates the nature of the state. However, since the underlying state machine of a resource is an encapsulated detail of a service and is not externally documented for Hypermedia APIs, the name is less a factor than the groups of available transitions.

At this stage, the state machine looks like the one shown in Figure 1.

![Missing Figure 1][]

Figure 1 Initial State Machine of eBooks/eBook Resources*

### Analyze unique sets of permissions
Once you isolate a set of states by analyzing similar groups of transitions dictated by business rules that are associated with the 'state' of the data, you must assess for each state which transitions are available based on context; for example, permissions, roles, and so on. To do this, you construct grids for each state permission. The grids map which transitions are available in which state (assuming there is more than one for the resource). Table 1 shows how the grid for eBooks looks at this stage. Table 2 shows the grid for eBook. Table 3 shows the grid for the published state. 

#### eBooks Example

<table class="confluenceTable">
    <tbody>
        <tr>
            <th>Context</th>
            <th>List</th>
            <th>Search</th>
            <th>Create</th>
        </tr>
        <tr>
            <td>Author</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
        </tr>
        <tr>
            <td>Publisher</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
        </tr>
        <tr>
            <td colspan="1">Everyone</td>
            <td colspan="1">Y</td>
            <td colspan="1">Y</td>
            <td colspan="1">N</td>
        </tr>
    </tbody>
</table>

Table 1 Collection/Navigation State Context Analysis

#### eBook Example

<table>
    <tbody>
        <tr>
            <th>Context</th>
            <th>Read</th>
            <th>Edit</th>
            <th>Copy</th>
            <th>Publish</th>
            <th>Delete</th>
            <th colspan="1">Author</th>
        </tr>
        <tr>
            <td>Author</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td colspan="1">Y</td>
        </tr>
        <tr>
            <td>Publisher</td>
            <td>Y</td>
            <td>N/Y*</td>
            <td>N/Y*</td>
            <td>N/Y*</td>
            <td>N/Y*</td>
            <td colspan="1">Y</td>
        </tr>
        <tr>
            <td colspan="1">Everyone</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
        </tr>
    </tbody>
</table>

\* A publisher can only perform these functions if the author has made the draft visible for review. 
(From the business requirements.)

Table 2 Draft State Context Analysis
 
<table>
    <tbody>
        <tr>
            <th>Context</th>
            <th>Read</th>
            <th>Edit</th>
            <th>Copy</th>
            <th>Publish</th>
            <th>Delete</th>
            <th colspan="1">Author</th>
        </tr>
        <tr>
            <td>Author</td>
            <td>Y</td>
            <td>N</td>
            <td>N</td>
            <td>N</td>
            <td>N</td>
            <td colspan="1">Y</td>
        </tr>
        <tr>
            <td>Publisher</td>
            <td>Y</td>
            <td>N</td>
            <td>N</td>
            <td>N</td>
            <td>N</td>
            <td colspan="1">Y</td>
        </tr>
        <tr>
            <td colspan="1">Everyone</td>
            <td colspan="1">Y</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">Y</td>
        </tr>
    </tbody>
</table>

Table 3 Published State Context Analysis
 
Table 2 shows that there are different rules for a Publisher than for an Author who are associated with the same set of transitions that are available on the resource. This situation arises when there is actually another state that may not initially have been obvious. In this case, the rules associated with an author who makes a Draft visible; that is, a "Rough Draft" versus a "Draft." This may seem artificial, but it illuminates the fact that different permission sets surface different states for the same set of transitions.

As such, Table 4 outlines the permissions for the rough draft state more accurately. Table 5 shows the permissions for the draft state.
 
<table>
    <tbody>
        <tr>
            <th>Context</th>
            <th>Read</th>
            <th>Edit</th>
            <th>Copy</th>
            <th>Publish</th>
            <th>Delete</th>
            <th colspan="1">Author</th>
        </tr>
        <tr>
            <td>Author</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td colspan="1">Y</td>
        </tr>
        <tr>
            <td>Publisher</td>
            <td>Y</td>
            <td>N</td>
            <td>N</td>
            <td>N</td>
            <td>N</td>
            <td colspan="1">Y</td>
        </tr>
        <tr>
            <td colspan="1">Everyone</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
        </tr>
    </tbody>
</table>

Table 4 Rough Draft State Context Analysis
 
<table>
    <tbody>
        <tr>
            <th>Context</th>
            <th>Read</th>
            <th>Edit</th>
            <th>Copy</th>
            <th>Publish</th>
            <th>Delete</th>
            <th colspan="1">Author</th>
        </tr>
        <tr>
            <td>Author</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td colspan="1">Y</td>
        </tr>
        <tr>
            <td>Publisher</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td>Y</td>
            <td colspan="1">Y</td>
        </tr>
        <tr>
            <td colspan="1">Everyone</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
            <td colspan="1">N</td>
        </tr>
    </tbody>
</table>

Table 5 Draft State Context Analysis

## Iterate for reusable semantics
Sometimes during state-machine analysis it becomes apparent that initial semantics are not the most applicable in light of initially unrecognized functionality, states, and so on. In this case, you could ask whether "Publish" is the best transition name to give. That is, it seems strange to say that I am publishing a rough draft. It may be fine, but for the sake of argument one could determine that the more accurate name is "release." If I "release" a Rough Draft, it becomes a Draft and has those permissions. If I "release" a Draft it becomes published and has a completely 
different set of transitions, and so on.

After this further analysis, the resource state machine looks like the one shown in Figure 2:

![Missing Figure 2][]

Figure 2 Completed State-machine of eBooks/eBook Resources

### State Design Pattern
That the "release" link relation performs different things as a function of state is an example of the State Design Pattern that underlies the eBook resource. By using this pattern when applicable, one minimizes the number of unique link relations for a resource.

## Analyze Transition Conditions
A final step in analyzing a state machine is to define the conditions that must be present for including a link 
relation in a response. You can use this conditional information in external authorization systems or locally to determine from the context of a request what conditions apply. These condition names can be arbitrary or follow some canonical convention. Regardless, if the conditions for some link relation are to be present in a response independent of their existence for the state of the resource, then a Hypermedia API must not return that link in a response.

In analyzing the permission matrices above, one notices that anyone can Read an eBook or look up an Author. As such, 
there are no context-related conditions on those resources. Thus, Table 6 highlights the Conditions Matrix of the sample eBook resource:

<table>
    <tbody>
        <tr>
            <th>Link Relation</th>
            <th>Condition</th>
        </tr>
        <tr>
            <td colspan="1">Read</td>
            <td colspan="1">is_author, can_read</td>
        </tr>
        <tr>
            <td colspan="1">Create</td>
            <td colspan="1">can_create_ebook</td>
        </tr>
        <tr>
            <td>Edit</td>
            <td>is_author, can_edit</td>
        </tr>
        <tr>
            <td>Copy</td>
            <td><span><span>is_author</span>, can_create_ebook, can_copy</span></td>
        </tr>
        <tr>
            <td>Release</td>
            <td><span><span>is_author</span>, can_release</span></td>
        </tr>
        <tr>
            <td>Delete</td>
            <td><span><span>is_author</span>, can_delete</span></td>
        </tr>
        <tr>
            <td colspan="1">Author</td>
            <td colspan="1">is_author, can_read</td>
        </tr>
    </tbody>
</table>

Table 6 eBooks/eBook Conditions Matrix

[Sample eBooks Hypermedia Contract]: sample_ebooks_hypermedia_contract.md
[Missing Figure 1]: http://www.plantuml.com:80/plantuml/png/TL2x3i8m3Dpz5HOZKd-W0nAF6R4ZXj2wJKH4giH5GgZ_JaY0fg5ibxkpVHV7WWaNj37cuXOe74Q83zWQhQbYPQvO52jCdYKwqarks8kRQiNN86mb8U5cB7v7PfWSqSen371SdZ8D05oIUuoTfRQgbUmdTrOqx1TMblpKvEOVItmMYH3I_j9KAvwXAzFT4_hGdtqPIRMNkeXXv797E3LyAgvxbiQ6ZX7wakFcDrMY223Rcgi39AElVosn9arCJm00
[Missing Figure 2]: http://www.plantuml.com:80/plantuml/png/VP5D3e8m48NtSug9InCkmCB4dxKnResBMWPARAnfYuantDrQK4gBx8RtFkRDJ8rbbd116wMkPe7CO5VY2xPAIkAsLZVCiXK6dpaQacKCxDcZhjWFO9eB2BG9nFMO1wPwZEQGjR7GmcbvZZm0CC5gmsRfOaVLL6AdMMbTGwx9_HLdJY61bY1-jJc0YjhE0bpTdp7mzJH9OeO0Kii7fxAFIsKVCiY7vkBkAQW8CWOj9doKktr_vdLZXTB-pbtf3XtDt-ivCb_0VsUS6hijn9q_xvzZuMPs3pCjlm40
