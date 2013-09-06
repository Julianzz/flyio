describe "A suite", ->

  beforeEach ->
    foo =
      setBar: (value)->
        bar = value
    foo.setBar(123)
    foo.setBar(456, 'another param')
  
  it "test vfs spawn", ->
    expect(true).toBe(true)
    
  it "tracks that the spy was called", () ->
    expect(foo.setBar).toHaveBeenCalled() 
