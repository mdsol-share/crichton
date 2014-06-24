# @title Sample eBooks State-machine Analysis

# Overview
In order to determine the appropriate the state-machine associated with a resource, or set of closely related resources, 
one must understand concepts and principles behind:

1. [Finite State Machines](http://en.wikipedia.org/wiki/Finite-state_machine)
2. [State Design Pattern](http://en.wikipedia.org/wiki/State_pattern)

Further, one understand the constraints on available state-transitions based on:

1. Business Rules driven by the data properties
2. Permissions driven by context (Roles, Traits, etc.)

Assuming initial semantic analysis associated with resources data and link relations has been performed, the following 
discussion outlines steps on how to determine the appropriate state-machine that represents the resource workflow and 
relationships to other resources.

## Hypermedia State Transitions
Available state-transitions are present in Hypermedia responses (depending on media-type) as links with defined link 
relations. These transitions, discovered at runtime, will transition either resource state or application state.

### Resource State Transitions
Resource state transitions transform the state of a resource such as updating properties, locking them, etc. As a rule 
of thumb, these transitions are semantically defined as verbs.

### Application State Transitions
Application state transitions transform the state of an application, which effectively means transitions state from one 
resource to another. As a rule of thumb, these transitions are semantically defined as nouns.

## Finding the states
Depending on the nature of the workflow associated with a particular resource or related set of resources, the state(s) 
of the resource may be obvious or take a while to expose. Technically, one could argue that for any resource where one 
can modify the underlying data, there are infinite resource states. Though, this is accurate, it is not really a useful 
concept in determining the states and related transitions for a Hypermedia API. 

> States are associated with distinct sets of possible state-transitions or dissimilar permission rules for the same set
of transitions in a resource.

The following outlines a number of ideas and constraints to determine the state-machine API of resources. For the sake 
of illustration, we will work on the related state-machines of the 'eBooks' and 'eBook' resources that were analyzed 
and summarized in the [Sample eBooks Hypermedia Contract][].

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
Business Rules associated with the underlying work a resource does dictate which link relations are available based on 
some aspect of the data. This may be some combination of data elements to define the state or effectively some property, 
like a "status" on underlying data. In order to initially determine states, one attempts to find groups of resources 
that are context independent. That is, for example, they exist on the state for some user or they don't exist on a 
state regardless of use.

#### eBooks Example
In our sample analysis, we initially find two states which we call Draft and Published with the following link 
relations:

* Collection: list (self), search, create
* Navigation: list, search (self), create

One could argue that a single state would be sufficient for a resource that lists other resources. However, as a 
practice, once you have applied a search or filter transition, the data of the resource is in a different state than 
the base URI of the resource as the full collection (even if it is paginated).

#### eBook Example
In our sample analysis, we initially find two states which we call Draft and Published with the following link 
relations:

* Draft: read (self), edit, copy, publish, delete, author
* Published: read (self), author

The name of the states, ideally encapsulate the nature of the state, but since the underlying state-machine of a 
resource is an encapsulated detail of a service and not externally documented for Hypermedia APIs, it is less a 
factor than the groups of available transitions.

![Missing Figure 1][]

Figure 1 Initial State-machine of eBooks/eBook Resources*

### Analyze unique sets of permissions
Once a set of states are isolated by analyzing like groups of transitions dictated solely by business rules associated 
with the 'state' of the data, it is necessary to assess for each state, which transitions are available based on context 
(e.g. permissions, role, etc.). To do this, one constructs for each state permission grids that map which transitions 
are available in which state (assuming there is more than one for the resource).

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

\* A publisher can only perform these functions if the author has made the draft visible for review 
(from business requirements).

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
 
Upon analyzing Table 2, it follows that there are different rules for a Publisher than for an Author associated with the 
same set of transitions that are generally available on the resource. This situation arises when there is actually 
another state around that may not initially have been obvious, In this case, until an author makes a Draft visible. 
That is, a "Rough Draft" vs. a "Draft". This may be seem artificial, but it is more for illumination that different 
permission sets surface different states for the same set of transitions.

As such, the following outlines the permissions for the states more accurately.
 
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

## Iterate for re-usable semantics
Sometimes in the course of state-machine analysis, it becomes apparent initial semantics are not the most applicable in 
light of initially unrecognized functionality, states, etc. In this case, one could ask whether "Publish" is the best 
transition name given, it is a bit of a force fit to say I am publishing a Rough Draft. It may be fine, but for the 
sake of contrived argument, one may determine that the more applicable name is "Release". If I "release" a Rough Draft, 
it becomes a Draft and has those permissions. If I "release" a Draft it becomes published and has a completely 
different set of transitions, etc.

At this point, the resource state-machine has evolved to:

![Missing Figure 2][]

Figure 2 Completed State-machine of eBooks/eBook Resources

### State Design Pattern
The "release" link relation doing different things as a function of state is an example of the State Design Pattern 
underlying the eBook resource. By using this pattern when applicable, one can minimize the number of unique link 
relations associated with a resource.

## Analyze Transition Conditions
On final step in analyzing a state-machine is to define the conditions that must be present for the inclusion of a link 
relation in a response. This information can be used in external authorization systems or locally to determine from the 
context of a request what conditions apply. These conditions names can be arbitrary or follow some canonical convention. 
Regardless, if the conditions for some link relation to be present in a response, regardless of their existence for the 
state of the resource, a Hypermedia API must not return that link in a response.

In analyzing the above permission matrices, one notices that anyone can Read an eBook or look up an Author. As such 
there are no context related conditions on those resources. Thus, the following highlights the Conditions Matrix of the 
sample eBook resource:

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
