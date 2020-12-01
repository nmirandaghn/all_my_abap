report  zclass.

class cl_animal definition abstract.
  public section.
    methods: constructor importing i_name type string, " Visible to everyone
             make_a_sound,
             my_name_is,
             get_type,
             introduce_me.

  protected section. " Visible only in child classes
    data p_class type string.

  private section. " Visible only internally
    data p_name type string.
endclass.

class cl_animal implementation.
  method constructor.
    p_name = i_name.     " p_name was defined already in the definition part of the class as private
    p_class = 'Unknown'. " p_class was defined already in the definition part of the class as protected
  endmethod.

  method make_a_sound.
    write 'Nothing'.
  endmethod.

  method my_name_is.
    write: / 'My name is: ', p_name.
  endmethod.

  method get_type.
    write: / 'I''m type of: ', p_class.
  endmethod.

  method introduce_me.
    me->my_name_is( ). " The keyword 'me' is used to specify class member. Is the equivalent of the keyword 'this' in C#
    make_a_sound( ).
    get_type( ).
  endmethod.
endclass.

class cl_dog definition inheriting from cl_animal.
  public section.
    methods: constructor importing i_dog_name type string,
             make_a_sound redefinition. " Change the behaviour of the method. Reimplement the code.
endclass.

class cl_dog implementation.
  method constructor.
    super->constructor( i_dog_name ). " Initialize the constructor and internally pass the parameter to the abstract class
    p_class = '"Dog"'.                " This is the protected member which is visible only in child classes
  endmethod.

  method make_a_sound.
    write: / 'My sound is:', 'Woof, woof'.
  endmethod.
endclass.

class cl_cat definition inheriting from cl_animal.
  public section.
    methods: constructor importing i_cat_name type string,
             make_a_sound redefinition.
endclass.

class cl_cat implementation.
  method constructor.
    super->constructor( i_cat_name ).
    p_class = '"Cat"'.
  endmethod.

  method make_a_sound.
    write: / 'My sound is:', 'Meow, meow'.
  endmethod.
endclass.

class cl_animal_factory definition.
  public section.
    class-methods create_animal importing i_animal type i returning value(r_animal) type ref to cl_animal. " Class method, in C# this is called a static method
endclass.

class cl_animal_factory implementation. " Factory pattern
  method create_animal.
    case i_animal.
      when 1.
        data dog type ref to cl_dog.
        create object dog exporting i_dog_name = 'Sparky'.
        r_animal = dog. " It is returned a cl_dog instance.
      when 2.
        data cat type ref to cl_cat.
        create object cat exporting i_cat_name = 'Fluffy'.
        r_animal = cat. " It is returned a cl_cat instance.
      when others.
    endcase.
  endmethod.
endclass.

class cl_introducer definition.
  public section.
    class-methods introduce importing i_animal type ref to cl_animal. " Here the method receives a cl_animal type parameter
endclass.

class cl_introducer implementation.
  method introduce.
    if i_animal is not initial.
      i_animal->introduce_me( ).
    else.
      write / 'I''m nothing'.
    endif.
  endmethod.
endclass.

start-of-selection.
  data wa_animal type ref to cl_animal.

  wa_animal = cl_animal_factory=>create_animal( 1 ).
  cl_introducer=>introduce( wa_animal ). " The i_animal parameter is implicitly specified. Useful when is only one parameter.
  write /.

  wa_animal = cl_animal_factory=>create_animal( 2 ).
  cl_introducer=>introduce( i_animal = wa_animal ). "  The i_animal parameter is explicitly specified and is necessary its use when is more than one paramter.
  write /.

  wa_animal = cl_animal_factory=>create_animal( 3 ).
  cl_introducer=>introduce( wa_animal ).